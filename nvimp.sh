#!/bin/bash

# p - start neovim in the specified directory, the directory starts from ~/dev/
# q - query project name
# N - start neovim in a newly created directory with the name
#
# n - used with p and N; specifies the number of terminal windows needed to be opened alongside neovim

NUMBER_OF_WINDOWS=1
ARGS_LENGTH=$#
declare -a SEEN_FLAGS=()

function nvim_in_existing_dir {
    if [[ ! -d ~/dev/$1 ]]; then
        echo "$HOME/dev/$1 doesn't exist. Try nvimp -N $1"
        exit 1
    else
        cd ~/dev/$1

        if [[ ! $NUMBER_OF_WINDOWS =~ ^[0-9]+$ ]]; then
            echo "Invalid argument for -n flag. Must be a positive integer"
            exit 1
        fi

        for i in $(seq 1 $NUMBER_OF_WINDOWS); do
            # the command to launch a kitty terminal window, requires allow_remote_control in kitty.conf
            kitten @ launch --title $1 --keep-focus --bias 20 --cwd ~/dev/$1 > /dev/null
        done

        nvim .
    fi

    exit 0
}

function query_dirs {
    find ~/dev -mindepth 1 -maxdepth 1 -iregex ".*$1.*" -type d -printf "%P\n"

    exit 0
}

function nvim_in_new_dir {
    if [[ -d ~/dev/$1 ]]; then
        echo "$HOME/dev/$1 already exists. Try nvimp -p $1"
        exit 1
    fi

    mkdir -v ~/dev/$1
    nvim_in_existing_dir $1
}

function process_unknown_flag {
    if [[ ! $1 =~ '-' && ! ${#SEEN_FLAGS[@]} =~ '-p' ]]; then
        echo "WARN: Missing -p flag. $1 is implied to be a project name"

        nvim_in_existing_dir $1
    fi

    echo "Unknown flag $1"
    exit 1
}

# if dev dir doesnt exist
if [ ! -d ~/dev ]; then
    read -p "/dev directory doesn't exist in $HOME. Create? [y/n] " answer

    if [[ $answer -eq "y" ]]; then
        mkdir ~/dev
        echo "$HOME/dev was successfully created!"
    elif [[ $answer -eq "n" ]]; then
        exit 1
    else
        echo "$answer isn't an option"
        exit 1
    fi
fi

for (( i=1; i<=$ARGS_LENGTH; i+=2 )); do
    j=$((i+1))

    #account for odd number of arguments!!
    #maybe we shouldnt step over arguments?
    #if no j -- do something

    if [[ ${!i} == '-n' ]]; then
        NUMBER_OF_WINDOWS="${!j}"
    fi

    SEEN_FLAGS+=${!i}
done

for (( i=1; i<=$ARGS_LENGTH; i+=2 )); do
    j=$((i+1))

    case ${!i} in
        -p) nvim_in_existing_dir "${!j}";;
        -N) nvim_in_new_dir "${!j}";;
        -q) query_dirs "${!j}";;
        *) process_unknown_flag "${!i}";;
    esac
done

exit 1
