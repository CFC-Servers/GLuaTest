#!/bin/bash

home=/home/steam
gmodroot=$home/gmodserver
server=$home/gmodserver/garrysmod
pat=$GITHUB_TOKEN@
timeout="${TIMEOUT:-2}"m

if [ "$GLUATEST_SLIM_PROBE" = "true" ]; then
    # docker-slim only keeps the git transport helpers if a clone uses them during the build
    git clone --depth 1 git@github.com:CFC-Servers/GLuaTest.git _tmp_ssh &> /dev/null
    git clone --depth 1 https://github.com/CFC-Servers/GLuaTest.git _tmp_https &> /dev/null
    rm -rf _tmp_ssh _tmp_https
fi

# Copy the overrides overtop the server files
echo "Copying serverfiles overrides..."
rsync --verbose --archive $home/garrysmod_override/ $server/

# Any additional files
if [ -n "$(ls -A $home/_gluatest_artifacts/_gluatest_artifacts/)" ]; then # Only execute if there are any artifacts or else tar will complain
    cp $home/_gluatest_artifacts/_gluatest_artifacts/* $gmodroot/

    for file in "$gmodroot"/*.tar.gz; do \
        tar --extract --verbose --ungzip --file="$file" --directory="$gmodroot" && \
        rm --force --verbose "$file"; \
    done
fi

if [ -f "$gmodroot/custom_requirements.txt" ]; then
    echo "Appending custom requirements"
    cat "$gmodroot/custom_requirements.txt" >> "$gmodroot/requirements.txt"
fi

hello_project_name="${HELLO_PROJECT_NAME:-}"
# 'CFC-Servers/GLuaTest"; quit' -> 'CFC-Servers/GLuaTestquit'
hello_project_name="${hello_project_name//[^A-Za-z0-9._\/-]/}"
if [ -n "$hello_project_name" ]; then
    echo "Usage ping project name: $hello_project_name"
    printf '\ngluatest_http_hello_project "%s"\n' "$hello_project_name" >> "$server/cfg/test.cfg"
fi

hello_runner="${HELLO_RUNNER:-}"
# 'agent/claude-code"; quit' -> 'agent/claude-codequit'
hello_runner="${hello_runner//[^A-Za-z0-9._\/-]/}"
if [ -n "$hello_runner" ]; then
    printf '\ngluatest_http_hello_runner "%s"\n' "$hello_runner" >> "$server/cfg/test.cfg"
fi

if [ "$HELLO_PING" = "false" ]; then
    echo "Usage ping turned off"
    printf '\ngluatest_http_hello 0\n' >> "$server/cfg/test.cfg"
fi

if [ -f "$gmodroot/custom_server.cfg" ]; then
    echo "Appending custom server configs"
    cat "$gmodroot/custom_server.cfg" >> "$server/cfg/test.cfg"
fi

echo "false" > "$server/data/gluatest_clean_exit.txt"
touch "$server/data/gluatest_failures.json"

if [[ ! -z "$SSH_PRIVATE_KEY" ]]; then
    echo "Private key found, adding"
    eval "$(ssh-agent -s)"
    ssh-add - <<< "$SSH_PRIVATE_KEY"
fi

while read -r requirement || [ -n "$requirement" ]; do
    if [ -z "$requirement" ]; then continue; fi
    echo "Handling requirement: $requirement"

    # 'CFC-Servers/GLuaTest@main' -> 'CFC-Servers/GLuaTest'
    repo="${requirement%%@*}"

    # 'CFC-Servers/GLuaTest' -> 'GLuaTest'
    name="${repo#*/}"
    # 'GLuaTest' -> 'gluatest'
    name="${name,,}"

    clone_args=( --depth 1 --single-branch )
    if [[ "$requirement" == *@* ]]; then
        # 'CFC-Servers/GLuaTest@main' -> 'main'
        branch="${requirement#*@}"
        clone_args+=( --branch "$branch" )
    fi

    if [[ -z "$SSH_PRIVATE_KEY" ]]; then
        git clone -vv "${clone_args[@]}" "https://${pat}github.com/$repo.git" "$server/addons/$name"
    else
        git clone -v "${clone_args[@]}" "git@github.com:$repo.git" "$server/addons/$name"
    fi
done <"$gmodroot"/requirements.txt

gamemode="${GAMEMODE:-sandbox}"
collection="${COLLECTION_ID:-0}"
map="${MAP:-gm_construct}"
echo "Starting the server with gamemode: $gamemode"

# '-maxplayers 64 +sv_cheats 1' -> ( -maxplayers 64 +sv_cheats 1 )
read -r -a srcds_args -d '' <<< "$EXTRA_STARTUP_ARGS"

srcds_args+=(
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

cd "$gmodroot" || exit 1 # srcds_run64 uses relative paths unlike srcds_run. Annoying...

if [ "$GLUATEST_SLIM_PROBE" = "true" ] && [ -x "$gmodroot/srcds_run64" ]; then
    # docker-slim only keeps files that were touched soo for dev 64x we also touch it :3
    unbuffer timeout "$timeout" "$gmodroot"/srcds_run64 "${srcds_args[@]//27015/27016}" &
fi

if [ "$USE_64BIT" = "true" ]; then
    echo "Starting 64-bit server"
    unbuffer timeout "$timeout" "$gmodroot"/srcds_run64 "${srcds_args[@]}"
elif [ -x "$gmodroot/srcds_run_x64" ]; then
    echo "Starting x86-64-bit server"
    unbuffer timeout "$timeout" "$gmodroot"/srcds_run_x64 "${srcds_args[@]}"
else
    echo "Starting 32-bit server"
    unbuffer timeout "$timeout" "$gmodroot"/srcds_run "${srcds_args[@]}"
fi

status=$?

if [ "$status" -ne 0 ]; then
    echo "::error:: Something went wrong! - Failing workflow"
    exit "$status"
fi

if [ -f "$gmodroot/debug.log" ]; then
	cat "$gmodroot/debug.log" # Dump the entire debug log

	echo "::error:: Server crashed! - Failing workflow"
	exit 1
fi

if [ ! -f "$server/data/gluatest_clean_exit.txt" ] || [ "$(cat $server/data/gluatest_clean_exit.txt)" = "false" ]; then
    echo "::warning:: Test runner did not exit cleanly. Test results unavailable!"
    exit 1 # This should never happen normally, GLuaTest probably had an error while executing so we should fail.
fi

if [ -s "$server/data/gluatest_failures.json" ]; then
    echo "::warning:: Test failures detected - Failing workflow"
    exit 1
else
    echo "No test failures detected"
    exit 0
fi
