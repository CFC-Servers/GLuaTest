#!/bin/bash

gmodroot=/home/steam/gmodserver
server=/home/steam/gmodserver/garrysmod

cat "$gmodroot/custom_requirements.txt" >> "$gmodroot/requirements.txt"
cat "$gmodroot/custom_server.cfg" >> "$server/cfg/test.cfg"
echo "false" > "$server/data/gluatest_clean_exit.txt"
touch "$server/data/gluatest_failures.json"

cd "$server"/addons
function getCloneLine {
    python3 - <<-EOF
line = "$1"
spl = line.split("@")

name = spl[0].split("/")[1].lower()
url = "https://github.com/" + spl[0] + ".git"

branch = " --branch " + spl[1] if len(spl) > 1 else ""

print("git clone -v " + url + branch + " --single-branch " + name)
EOF
}

while read p; do
    echo "$p"
    eval $(getCloneLine "$p")
done <"$gmodroot"/requirements.txt

echo "Pre-server run. LS'ing data folder"
ls -alh "$server/data"

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
    +gamemode sandbox
    +map gm_construct
    -maxplayers 12
    +servercfgfile test.cfg
    -disableluarefresh
    +mat_dxlevel 1
)

stdbuf -oL -eL timeout 2m "$gmodroot"/srcds_run_x64 "${srcds_args[@]}"
status=$?

if [ "$(cat $server/data/gluatest_clean_exit.txt)" = "false" ]; then
    exit "$status"
fi

if [ -s "$server/data/gluatest_failures.json" ]; then
    echo "::warn ::Test failures detected - Failing"
    exit 1
else
    echo "::info ::No test failures detected"
    exit 0
fi
