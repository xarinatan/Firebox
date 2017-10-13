#!/bin/bash

trap ctrl_c INT
weAreRunning=false 

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
                    run_Main
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
        run_Main
    fi
    
}


function run_Main(){
    touch .lock
    weAreRunning=true
    echo "Starting custom firefox with no RPC and custom local profile.."
    /usr/lib/firefox/firefox --profile ./ffprofile --no-remote > console.log 2>&1 & # Really this is the core of the script. The rest is just making sure this works well across machines and such :v.
    FirefoxPID=`echo $!`
    echo $FirefoxPID > .lock
    RunCheck=true
    while $RunCheck; do
        if [ -f ./.kill ]; then
            MSG=`cat ./.kill`
            echo -n "Kill request found with message $MSG. " 
            RunCheck=false
            clean_Exit
        fi
        
        if ! ps -p $FirefoxPID > /dev/null
        then
            echo "Firefox($FirefoxPID) is not running. Did it crash?"
            clean_Exit
        fi
            
        sleep 2;
    done
}

function clean_Exit(){
    echo "Cleaning up and exiting script.."
    FirefoxPID=`cat .lock` #other variable is out of scope here, so read it from the lock file
    if ps -p $FirefoxPID > /dev/null
    then
        echo "Firefox is still running. Killing Firefox.."
        kill $FirefoxPID #TODO: Is there a cleaner way? Even though just sending sigterm isn't that harsh..
    fi
    rm -f ./.lock 
    rm -f ./.kill
    exit
}


check_for_lock #Checks for locks and runs the main function

echo "Something went wrong.. This part of the script isn't meant to be run. Did spacetime collapse?"
