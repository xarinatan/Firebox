#!/bin/bash
#note: the 'start' of the script is at the bottom. main() is ran which checks for lock files and if there are none, Firefox is executed.

trap ctrl_c INT
weAreRunning=false
interactive=false
FirefoxPID=0
PROFILE_PATH="ffprofile"
firefoxexe=$(which firefox)

LOCKFILE=".lock"
KILLFILE=".kill"

function ctrl_c() {
    if $weAreRunning ;
    then
        echo -n "Ctrl+C Caught. "
        cleanup
    else
        echo "Ctrl+C Caught. Terminating script (leaving lock files in tact)"
        exit
    fi
    
}

function request_lock_removal() {
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
                if check_for_lock; then 
                    echo -n "."
                else
                    waiting=false
                    echo "!"
                    main
                fi
            sleep 2; done
            exit
            ;;
        *)
            echo "Please close the remote session and make sure there's no more lock file."
            exit
            ;;
        esac
}

function create_profile() {
    
    if [ -e $PROFILE_PATH ] ; then
        echo "Profile path string is empty!"
        exit 
    fi

    mkdir $PROFILE_PATH
    read -r -p "New profile created. do you want to copy the template user.js into the new profile for some default settings? (enable usercontexts, dark-compact theme, etc, check template-user.js for more details) [y/N]" response
    case "$response" in
        [yY][eE][sS]|[yY])
            cp template-user.js ./$PROFILE_PATH/user.js
        ;;
        *)
            main
        ;;
esac
}

function check_for_lock() {
    if [ -f $LOCKFILE ] ; then 
        return 0
    else
        return 1
    fi
    
}

function remove_lock() {
    if [ "$FirefoxPID" -eq "0" ] ; then 
        return 1 #Firefox hasn't been succesfully started
    fi
    rm $LOCKFILE
}

function create_lock() {
    if [ "$FirefoxPID" -eq "0" ] ; then 
        return 1 #Firefox hasn't been succesfully started
    fi
    touch $LOCKFILE
}

function update_lock() {
    if [ "$FirefoxPID" -eq "0" ] ; then 
        return 1 #Firefox hasn't been succesfully started
    fi
    echo $(whoami) > $LOCKFILE
    echo " on machine " >> $LOCKFILE
    echo $(hostname) >> $LOCKFILE
}

# Really this is the core of the script. The rest is just making sure this works well across machines and such :v.
function run_firefox() {
    $firefoxexe --no-remote --profile ./$PROFILE_PATH > console.log 2>&1 &
    FirefoxPID=$!
}

function cleanup() {
    if [ "$FirefoxPID" -eq "0" ] ; then
        echo "Firefox process ID is 0, not performing cleanup"
    fi
    echo "Cleaning up Firefox PID $FirefoxPID"
    if ps -p $FirefoxPID > /dev/null
        then
        echo "Firefox PID $FirefoxPID still running, killing it..."
        kill $FirefoxPID || echo "Unable to kill firefox"
    fi
    echo deleting lockfiles..
    rm -f $LOCKFILE
    rm -f $KILLFILE
    exit
}

function monitor_firefox() {

        while RunCheck; do
            if [ -f $KILLFILE ]; then
                MSG=`cat $KILLFILE`
                echo -n "Kill request found with message $MSG. " 
                RunCheck=false
                cleanup
            fi
            
            if ! ps -p $FirefoxPID > /dev/null
            then
                echo "Firefox($FirefoxPID) is not running. Did it crash? "
                cleanup
            fi
            
            if [ ! check_for_lock ] ; then
                    echo -n "Lock file removed. Killing firefox $FirefoxPID.. "
                cleanup
            fi
            
            update_lock
            sleep 2;
        done
}

function RunCheck() {
    #This should return true if the process exists
    printf "\rCurrent process ID: $FirefoxPID   (Press ctrl+C to kill or close the app)"
    if [ "$FirefoxPID" -eq "0" ] ; then
        echo "firefox isnt started ($FirefoxPID)"
        return 1 #no firefox has been started yet
    else
        kill -0 $FirefoxPID 
    fi
}

function main() {
    if [ ! -d "$PROFILE_PATH" ] ; then
        create_profile
    fi
    
    if check_for_lock ; then
        request_lock_removal 
    fi

    
    weAreRunning=true
    run_firefox
    create_lock
    echo "Started Firefox on $FirefoxPID"
    monitor_firefox
    cleanup #in case shit happens, clean up
}

if [ -t 1 ] ; then 
    echo "Interactive terminal detected.."
    interactive=true
else 
    echo "WARNING: This shell is not interactive! Will exit if requiring user input.."
fi

main # main part of the script starts here, after the function definitions.
echo "Something went wrong.. This part of the script isn't meant to be run. Did spacetime collapse?"
