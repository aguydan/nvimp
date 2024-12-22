#!/bin/bash

# p - start neovim in the specified directory, the directory starts from ~/dev/
# q - query project name
# N - start neovim in a newly created directory with the name
# h - prints a list of all flags used with the command
#
# n - used with p and N; specifies the number of terminal windows needed to be opened alongside neovim

NUMBER_OF_WINDOWS=1
ARGS_LENGTH=$#
declare -a SEEN_FLAGS=()
declare -a SEEN_FLAG_ARGS=()

function nvim_in_existing_dir {
    if [[ ! -d ~/dev/$1 ]]; then
        echo "$HOME/dev/$1 doesn't exist. Try nvimp -N $1"
        exit 1
    fi

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
    if [[ ! $1 =~ ^-[a-z]$ && ! ${#SEEN_FLAGS[@]} =~ '-p' ]]; then
        echo "WARN: Missing -p flag. $1 is implied to be a project name"

        nvim_in_existing_dir $1
    fi

    echo "Unknown flag $1"
    exit 1
}

function print_help {
cat << EOF
p - start Neovim in the specified directory, the directory starts from ~/dev/
q - query project name
N - start Neovim in a newly created directory with the name
h - prints a list of all flags used with the command

n - used with p and N; specifies the number of terminal windows needed to be opened alongside Neovim
EOF

    exit 0
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

#distribute flags and their arguments
unset CURR_FLAG_INDEX

#move detection of unknown flags here because otherwise
#every additional flag currently is percieved as unknown!!!!!
for (( i=1; i<=$ARGS_LENGTH; i++ )); do
    # the command argument by the index i is a flag argument in this case
    if [[ ! ${!i} =~ ^-[a-z]$ ]]; then
        # special case when the first flag can be a project name
        if [[ i -eq 1 ]]; then
            CURR_FLAG_INDEX=1 
            SEEN_FLAGS[1]=${!i}

            continue
        fi

        SEEN_FLAG_ARGS[$CURR_FLAG_INDEX]+=${!i}

        continue
    fi

    # the command argument by the index i is a flag in this case
    CURR_FLAG_INDEX=$((CURR_FLAG_INDEX + 1))
    j=$((i+1))

    # if the supposed argument of the flag by the index of i is also a flag or null
    # we exit
    # but only if the flag by the index of i actually requires at least one arguments
    # -q and -n don't require arguments
    if [[ (${!j} =~ ^-[a-z]$ || -z ${!j}) && ! ${!i} =~ -[qh] ]]; then
        echo "Argument for the flag ${!i} was not provided"
        exit 1
    fi
    
    # check additional flags that should be processed before the main ones
    if [[ ${!i} == '-n' ]]; then
        NUMBER_OF_WINDOWS="${!j}"
    fi

    SEEN_FLAGS[$CURR_FLAG_INDEX]=${!i}
done

# check additional flags here if main werent used??
for (( i=1; i<=${#SEEN_FLAGS[@]}; i++ )); do
    case ${SEEN_FLAGS[$i]} in
        -h) print_help;;
        -p) nvim_in_existing_dir "${SEEN_FLAG_ARGS[$i]}";;
        -N) nvim_in_new_dir "${SEEN_FLAG_ARGS[$i]}";;
        -q) query_dirs "${SEEN_FLAG_ARGS[$i]}";;
        *) process_unknown_flag "${SEEN_FLAGS[$i]}";;
    esac
done

print_help
