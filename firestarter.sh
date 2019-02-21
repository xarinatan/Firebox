#!/bin/bash
#note: the 'start' of the script is at the bottom. Main() is ran which and if that succeeds, Main() is executed.

trap ctrl_c INT
weAreRunning=false
interactive=false
FirefoxPID=0
profileDirName="ffprofile"

function ctrl_c() {
    if weAreRunning ;
    then
        echo -n "Ctrl+C Caught. "
        clean_exit
    else
        echo "Ctrl+C Caught. Terminating script (leaving lock files in tact)"
        exit
    fi
    
}

function check_for_lock(){
    if [ -f ./.lock ]; then
        if  ! $interactive ; then
            echo "Cannot get user input. exiting.." 
            exit
        fi
        
        read -r -p "Lock exists. Do you want to issue a remote kill request? (WARNING Remote open data will be lost!)[y/N]" response
        case "$response" in
            [yY][eE][sS]|[yY]) 
            Time=`date`
            echo "Issued by $USER@$HOSTNAME at $Time" > ./.kill
            echo -n "Kill command issued. Please wait a short while to give the sync application and remote machine a chance to terminate the session (Press Ctrl+C at any time to abort and clean up)."
            waiting=true 
            while $waiting; do
                if [ -f ./.lock ]; then 
                    echo -n "."
                else
                    waiting=false
                    echo "!"
                    Main
                fi
            sleep 2; done
            exit
            ;;
        *)
            echo "Please close the remote session and make sure there's no more lock file."
            exit
            ;;
        esac
        
    else
        true
    fi
    
}

function first_run(){
    mkdir $profileDirName
    read -r -p "New profile created. do you want to copy the template user.js into the new profile for some default settings? (enable usercontexts, dark-compact theme, etc, check template-user.js for more details) [y/N]" response
    case "$response" in
        [yY][eE][sS]|[yY])
            cp template-user.js ./$profileDirName/user.js
        ;;
        *)
            Main
        ;;
    esac
}

function update_lockfile(){
        echo $FirefoxPID > .lock
        echo " on machine " >> .lock
        echo $HOSTNAME >> .lock
}


function Main(){
    if check_for_lock ; then
        touch .lock
        if [ ! -d "$profileDirName" ]; then
            if  ! $interactive ; then
                echo "Cannot get user input. exiting.." 
                exit
            fi
            first_run
        fi
        weAreRunning=true
        echo "Starting custom firefox with no RPC and custom local profile.."
        /usr/lib/firefox/firefox --profile ./$profileDirName --no-remote > console.log 2>&1 & # Really this is the core of the script. The rest is just making sure this works well across machines and such :v.
        FirefoxPID=`echo $!`
        RunCheck=true
        while $RunCheck; do
            if [ -f ./.kill ]; then
                MSG=`cat ./.kill`
                echo -n "Kill request found with message $MSG. " 
                RunCheck=false
                clean_exit
            fi
            
            if ! ps -p $FirefoxPID > /dev/null
            then
                echo "Firefox($FirefoxPID) is not running. Did it crash? "
                clean_exit
            fi
            
            if ! [ -f ./.lock ]; then
                    echo -n "Lock file removed. Killing firefox.. "
                    clean_exit
            fi
            
            update_lockfile
            sleep 2;
        done
    fi
}

function clean_exit(){
    echo "Cleaning up and exiting script.."
    
    if ps -p $FirefoxPID > /dev/null
    then
        echo "Firefox is still running. Killing Firefox.."
        kill $FirefoxPID #TODO: Is there a cleaner way? Even though just sending sigterm isn't that harsh..
    fi
    rm -f ./.lock 
    rm -f ./.kill
    exit
}

if [ -t 1 ] ; then 
    echo "Interactive terminal detected.."
    interactive=true
else 
    echo "WARNING: This shell is not interactive! Will exit if requiring user input.."
fi

Main #Main part of the script starts here, after the function definitions.

echo "Something went wrong.. This part of the script isn't meant to be run. Did spacetime collapse?"
