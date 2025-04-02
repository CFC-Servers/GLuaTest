#!/bin/bash

home=/home/steam
gmodroot=$home/gmodserver
server=$home/gmodserver/garrysmod
pat=$GITHUB_TOKEN@
timeout="${TIMEOUT:-2}"m

# Make sure docker-slim doesn't remove bins we'll eventually need
echo $(date)
python3 -c "print()" &> /dev/null
git clone --depth 1 git@github.com:CFC-Servers/GLuaTest.git _tmp_ssh &> /dev/null
git clone --depth 1 https://github.com/CFC-Servers/GLuaTest.git _tmp_https &> /dev/null
rm -rf _tmp_ssh _tmp_https

# Copy the overrides overtop the server files
echo "Copying serverfiles overrides..."
rsync --verbose --archive $home/serverfiles_override/ $gmodroot/

if [ -f "$gmodroot/custom_requirements.txt" ]; then
    echo "Appending custom requirements"
    cat "$gmodroot/custom_requirements.txt" >> "$gmodroot/requirements.txt"
fi

if [ -f "$gmodroot/custom_server.cfg" ]; then
    echo "Appending custom server configs"
    cat "$gmodroot/custom_server.cfg" >> "$server/cfg/test.cfg"
fi

echo "false" > "$server/data/gluatest_clean_exit.txt"
touch "$server/data/gluatest_failures.json"

if [[ ! -z "$SSH_PRIVATE_KEY" ]]; then
    echo "Private key found, adding"
    mkdir -pv /home/steam/.ssh
    cat /home/steam/github_known_hosts >> /home/steam/.ssh/known_hosts

    eval `ssh-agent -s`
    ssh-add - <<< "$SSH_PRIVATE_KEY"
fi

function getCloneLine {
    python3 - <<-EOF
line = "$1"
spl = line.split("@")

name = spl[0].split("/")[1].lower()
url = "https://${pat}github.com/" + spl[0] + ".git"

branch = " --branch " + spl[1] if len(spl) > 1 else ""

print("git clone -vv --depth 1 " + url + branch + " --single-branch " + name)
EOF
}

function getSSHCloneLine {
    python3 - <<-EOF
line = "$1"
spl = line.split("@")

name = spl[0].split("/")[1].lower()
url = "git@github.com:" + spl[0] + ".git"

branch = " --branch " + spl[1] if len(spl) > 1 else ""

print("git clone -v --depth 1 " + url + branch + " --single-branch " + name)
EOF
}

cd "$server"/addons
while read p; do
    echo "Handling requirement: $p"
    if [[ -z "$SSH_PRIVATE_KEY" ]]; then
        eval $(getCloneLine "$p" )
    else
        eval $(getSSHCloneLine "$p" )
    fi
done <"$gmodroot"/requirements.txt

gamemode="${GAMEMODE:-sandbox}"
collection="${COLLECTION_ID:-0}"
map="${MAP:-gm_construct}"
echo "Starting the server with gamemode: $gamemode"

base_srcds_args=(
    # Test requirements
    -systemtest       # Allows us to exit the game from inside Lua
    -condebug         # Logs everything to console.log
    -debug            # On crashes generate a debug.log allowing for better debugging.
    -norestart        # If we crash, do not restart.

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
    -threads 6        # Double the allocated threads to the threadpool

    -maxplayers 12
    -disableluarefresh
    +mat_dxlevel 1

    # Game setup
    -game garrysmod
    -ip 127.0.0.1
    -port 27015
    +clientport 27005
    +gamemode "$gamemode"
    +host_workshop_collection "$collection"
    +map "$map"
    +servercfgfile test.cfg
)
srcds_args="${base_srcds_args[@]} $EXTRA_STARTUP_ARGS"

echo "GMOD_BRANCH: $GMOD_BRANCH"

if [ "$GMOD_BRANCH" = "x86-64" ]; then
    echo "Starting 64-bit server"
    unbuffer timeout "$timeout" "$gmodroot"/srcds_run_x64 "$srcds_args"
else
    echo "Starting 32-bit server"
    unbuffer timeout "$timeout" "$gmodroot"/srcds_run "$srcds_args"
fi

if [ -f "$gmodroot/debug.log" ]; then
	cat "$gmodroot/debug.log" # Dump the entire debug log

	echo "::error:: Server crashed! - Failing workflow"
	exit 1
fi

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
