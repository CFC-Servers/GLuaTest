#!/bin/bash

gmodroot=/home/steam/gmodserver
server=/home/steam/gmodserver/garrysmod
pat=$GITHUB_TOKEN@

cat "$gmodroot/custom_requirements.txt" >> "$gmodroot/requirements.txt"
cat "$gmodroot/custom_server.cfg" >> "$server/cfg/test.cfg"
echo "false" > "$server/data/gluatest_clean_exit.txt"
touch "$server/data/gluatest_failures.json"

if [[ ! -z "$SSH_PRIVATE_KEY" ]]; then
    echo "Private key found, adding"
    mkdir -pv /home/steam/.ssh
    cat /home/steam/github_known_hosts >> /home/steam/.ssh/known_hosts

    eval `ssh-agent -s`
    ssh-add - <<< "$SSH_PRIVATE_KEY"
fi

cd "$server"/addons

function getCloneLine {
    python3 - <<-EOF
line = "$1"
spl = line.split("@")

name = spl[0].split("/")[1].lower()
url = "https://${pat}github.com/" + spl[0] + ".git"

branch = " --branch " + spl[1] if len(spl) > 1 else ""

print("git clone -vv " + url + branch + " --single-branch " + name)
EOF
}

function getSSHCloneLine {
    python3 - <<-EOF
line = "$1"
spl = line.split("@")

name = spl[0].split("/")[1].lower()
url = "git@github.com:" + spl[0] + ".git"

branch = " --branch " + spl[1] if len(spl) > 1 else ""

print("git clone -v " + url + branch + " --single-branch " + name)
EOF
}

# Make sure we get the latest version of gluatest
rm -rfv "$server"/addons/gluatest

while read p; do
    echo "$p"
    if [[ -z "$SSH_PRIVATE_KEY" ]]; then
        eval $(getCloneLine "$p" )
    else
        eval $(getSSHCloneLine "$p" )
    fi
done <"$gmodroot"/requirements.txt

gamemode="${GAMEMODE:-sandbox}"
collection="${COLLECTION_ID:-0}"
echo "Starting the server with gamemode: $gamemode"

srcds_args=(
    # Test requirements
    -systemtest       # Allows us to exit the game from inside Lua
    -condebug         # Logs everything to console.log

    # Disabling things we don't need/want
    -nodns            # Disables DNS requests and resolving DNS addresses
    -nohltv           # Disable SourceTV
    -nodttest         # Skips datatable testing
    -nomaster         # Hides server from master list
    -nominidumps      # Don't write minidumps
    -nop4             # No "Perforce" integration
    -noshaderapi      # Don't try to load other shader APIs, use the "shaderapiempty.dll"
    -nogamestats      # No need for game stats
    -noipx            # Disables IPX support
    -fs_nopreloaddata # "Loads in the precompiled keyvalues for each datatype"
    -hushasserts      # "Disables a number of asserts in core Source libraries, skipping some error checks and messages"
    -snoforceformat   # Skips sound buffer creation
    -insecure         # Disable VAC

    # Optimizations
    -collate          # "Skips everything, just merges the reslist from temp folders to the final folder again"
    -high             # Sets "high" process affinity
    -reuse            # Don't create new network sockets, reuse existing
    -threads 6        # Double the allocated threads to the threadpool

    # Game setup
    -game garrysmod
    -ip 127.0.0.1
    -port 27015
    +clientport 27005
    +gamemode "$gamemode"
    +host_workshop_collection "$collection"
    +map gm_construct
    -maxplayers 12
    +servercfgfile test.cfg
    -disableluarefresh
    +mat_dxlevel 1
)

stdbuf -oL -eL timeout 2m "$gmodroot"/srcds_run_x64 "${srcds_args[@]}"
status=$?

if [ "$(cat $server/data/gluatest_clean_exit.txt)" = "false" ]; then
    echo "::warning:: Test runner did not exit cleanly. Test results unavailable!"
    exit "$status"
fi

if [ -s "$server/data/gluatest_failures.json" ]; then
    echo "::warning:: Test failures detected - Failing workflow"
    exit 1
else
    echo "::notice:: No test failures detected"
    exit 0
fi
