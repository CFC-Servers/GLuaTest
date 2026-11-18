#!/usr/bin/env bash
set -euo pipefail

# Zero-config local GLuaTest runner.
#
# Run from your project directory (addon, gamemode, or server repo):
#   /path/to/GLuaTest/docker/run_local.sh
#
# Requires Docker with the compose plugin. Linux, macOS, or Windows via WSL2.

usage() {
    cat <<'EOF'
Usage: run_local.sh [options]

Runs your project's GLuaTest suite in Docker. Run it from your project
directory (or pass --project). The project layout is detected the same way
CI detects it: a full server (garrysmod/), garrysmod/ contents (gamemodes/),
a gamemode (gamemode/), or an addon (lua/).

If gluatest_requirements.txt or gluatest_custom.cfg exist in the project
root they are used automatically (the same filenames CI uses).

Options:
  --project <path>     Project directory to test (default: current directory)
  --branch <name>      GMod branch: public, x86-64, prerelease, dev (default: public)
  --gamemode <name>    Gamemode for the test server (default: sandbox)
  --map <name>         Map for the test server (default: gm_construct)
  --collection <id>    Workshop collection ID for the server to mount
  --timeout <minutes>  Minutes before the server is killed (default: 2)
  --filter <terms>     Only run test groups whose path or group name contains
                       one of these space-separated terms (case-insensitive)
  --build              Build the runner image locally instead of pulling the
                       published one (only for hacking on the image itself)
  --quiet              Suppress the live server output; the verdict and exit
                       code still print
  --help               Show this help

Every run writes the full server log to gluatest-run.log in the directory
you invoked from. Exit code 0 = all tests passed; 124 = server hit the
--timeout limit; 69 = Docker is missing or not running; anything else = test
failure or server error.

Each run checks GitHub for a newer version of this runner and its agent
skill, and prints a notice if one exists. Set GLUATEST_NO_UPDATE_CHECK=1 to skip the check.
EOF
}

EXIT_DOCKER_UNAVAILABLE=69
UPDATE_CHECK_URL="https://raw.githubusercontent.com/CFC-Servers/GLuaTest/main/.claude-plugin/plugin.json"
UPDATE_CHECK_TIMEOUT_SECONDS=3

err() {
    echo "run_local.sh: error: $*" >&2
    exit 1
}

note() {
    echo "==> $*"
}

docker_unavailable() {
    echo "run_local.sh: error: $*" >&2
    echo "AI agents: stop here and pass this message to the user. Do not install or start Docker yourself, and do not run the tests another way." >&2
    exit "$EXIT_DOCKER_UNAVAILABLE"
}

manifest_version() {
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1
}

notify_if_outdated() {
    [ -z "${GLUATEST_NO_UPDATE_CHECK:-}" ] || return 0
    command -v curl > /dev/null 2>&1 || return 0

    local repo_root="$SCRIPT_DIR/.."
    local manifest="$repo_root/.claude-plugin/plugin.json"
    [ -f "$manifest" ] || return 0

    local installed latest newest
    installed="$(manifest_version < "$manifest")"
    latest="$(curl -fsS --max-time "$UPDATE_CHECK_TIMEOUT_SECONDS" "$UPDATE_CHECK_URL" 2> /dev/null | manifest_version || true)"
    [ -n "$installed" ] && [ -n "$latest" ] || return 0

    newest="$(printf '%s\n%s\n' "$installed" "$latest" | sort -V | tail -n 1)"
    [ "$latest" != "$installed" ] && [ "$newest" = "$latest" ] || return 0

    local update_command="claude plugin update gluatest@gluatest (then run /reload-plugins or restart Claude Code)"
    if [ -d "$repo_root/.git" ]; then
        update_command="git -C \"$(cd "$repo_root" && pwd)\" pull --ff-only"
    fi

    note "A newer GLuaTest runner and agent skill is available ($latest, this copy is $installed). Update with: $update_command"
    note "AI agents: mention this update and its command to the user when you report the test results."
}

# --- Flags -------------------------------------------------------------------
PROJECT_DIR_ARG=""
GMOD_BRANCH="public"
GAMEMODE="sandbox"
MAP="gm_construct"
COLLECTION_ID=""
TIMEOUT="2"
FILTER=""
BUILD=0
QUIET=0

while [ $# -gt 0 ]; do
    case "$1" in
        --project)    PROJECT_DIR_ARG="${2:?--project requires a path}"; shift 2 ;;
        --branch)     GMOD_BRANCH="${2:?--branch requires a value}"; shift 2 ;;
        --gamemode)   GAMEMODE="${2:?--gamemode requires a value}"; shift 2 ;;
        --map)        MAP="${2:?--map requires a value}"; shift 2 ;;
        --collection) COLLECTION_ID="${2:?--collection requires a value}"; shift 2 ;;
        --timeout)    TIMEOUT="${2:?--timeout requires a value}"; shift 2 ;;
        --filter)     FILTER="${2:?--filter requires a value}"; shift 2 ;;
        --build)      BUILD=1; shift ;;
        --quiet)      QUIET=1; shift ;;
        --help|-h)    usage; exit 0 ;;
        *)            usage >&2; err "unknown option: $1" ;;
    esac
done

# Same back-compat rename CI applies
if [ "$GMOD_BRANCH" = "live" ]; then
    GMOD_BRANCH="public"
fi

case "$TIMEOUT" in
    ''|*[!0-9]*) err "--timeout must be a whole number of minutes (got: $TIMEOUT)" ;;
esac

case "$FILTER" in
    *[\"\;]*|*$'\n'*) err "--filter cannot contain quotes, semicolons, or newlines (got: $FILTER)" ;;
esac

# --- Preflight ----------------------------------------------------------------
COMPOSE_INSTALL_URL="https://docs.docker.com/compose/install/"

if [ "$(uname -s)" = "Darwin" ]; then
    docker_install_hint="Install Docker Desktop for Mac: https://docs.docker.com/desktop/"
    compose_install_hint="Docker Desktop includes Compose. Start Docker Desktop, or update it if it is already running."
    docker_start_hint="Start Docker Desktop and wait for it to finish starting."
elif grep -qi microsoft /proc/version 2> /dev/null; then
    docker_install_hint="If Docker Desktop is already installed on Windows, start it and enable this distro under Settings > Resources > WSL integration.
Otherwise install Docker Desktop (https://docs.docker.com/desktop/) or Docker Engine inside this distro (https://docs.docker.com/engine/install/)."
    compose_install_hint="If you use Docker Desktop, start it and enable this distro under Settings > Resources > WSL integration.
If Docker Engine is installed inside this distro, install the Compose plugin: $COMPOSE_INSTALL_URL"
    docker_start_hint="Start Docker Desktop on Windows, or if Docker Engine is installed inside this distro, run 'sudo service docker start'."
else
    docker_install_hint="Install Docker Engine: https://docs.docker.com/engine/install/"
    compose_install_hint="Install the Compose plugin: $COMPOSE_INSTALL_URL"
    docker_start_hint="Start it with 'sudo systemctl start docker'. If Docker reported a permission error, add your user to the docker group: https://docs.docker.com/engine/install/linux-postinstall/"
fi

command -v docker > /dev/null 2>&1 || docker_unavailable "GLuaTest runs its test server in Docker, and Docker is not installed (no 'docker' on your PATH).
$docker_install_hint"

docker compose version > /dev/null 2>&1 || docker_unavailable "the Docker Compose plugin is not available ('docker compose version' failed).
$compose_install_hint"

if ! docker_info_error="$(docker info 2>&1 > /dev/null)"; then
    docker_unavailable "Docker is installed but not running or not reachable.
Docker reported: $(echo "$docker_info_error" | grep -v -e "^WARNING" -e "errors pretty printing" | head -n 3)
$docker_start_hint"
fi

arch="$(uname -m)"
if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
    # The runner image is amd64-only (srcds is x86)
    export DOCKER_DEFAULT_PLATFORM=linux/amd64
    note "arm64 host detected: the server will run under emulation and will be slower."
    if [ "$GMOD_BRANCH" != "x86-64" ]; then
        # 32-bit srcds needs robust futexes, which Rosetta/QEMU user emulation
        # don't provide - it dies at startup with a futex robust_list fatal
        note "the '$GMOD_BRANCH' branch server is 32-bit, which usually crashes under Apple Silicon emulation - if it dies on startup, retry with: --branch x86-64"
    fi
fi

# --- Locate the compose file (resolve symlinks so the script can live on PATH) -
script_source="${BASH_SOURCE[0]}"
while [ -L "$script_source" ]; do
    script_dir="$(cd -P "$(dirname "$script_source")" && pwd)"
    script_source="$(readlink "$script_source")"
    case "$script_source" in
        /*) ;;
        *) script_source="$script_dir/$script_source" ;;
    esac
done
SCRIPT_DIR="$(cd -P "$(dirname "$script_source")" && pwd)"
COMPOSE=(docker compose -f "$SCRIPT_DIR/docker-compose.yml")

# --- Resolve the project directory --------------------------------------------
INVOCATION_DIR="$PWD"
PROJECT="${PROJECT_DIR_ARG:-$PWD}"
[ -d "$PROJECT" ] || err "project directory does not exist: $PROJECT"
PROJECT="$(cd "$PROJECT" && pwd)"

# --- Temp dirs + cleanup --------------------------------------------------------
# Everything the compose file bind-mounts must live under $HOME: macOS Docker
# VMs only share limited host paths (colima shares $HOME; Docker Desktop shares
# /Users), and the system TMPDIR (/var/folders/...) is not among them - a bind
# source there silently becomes an empty directory inside the VM.
TMP_BASE="$HOME/.cache/gluatest"
mkdir -p "$TMP_BASE"
STAGING_DIR="$(mktemp -d "$TMP_BASE/stage.XXXXXX")"
ARTIFACT_DIR="$(mktemp -d "$TMP_BASE/artifacts.XXXXXX")"
PLACEHOLDER_DIR="$(mktemp -d "$TMP_BASE/placeholder.XXXXXX")"

cleanup() {
    status=$?
    "${COMPOSE[@]}" down > /dev/null 2>&1 || true
    rm -rf "$STAGING_DIR" "$ARTIFACT_DIR" "$PLACEHOLDER_DIR"
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# --- Stage the project into a garrysmod/ override layout -----------------------
# Mirrors CI's "Prepare the override directory" step in run_tests.yml.
source_dir="$PROJECT"
dest_dir="$STAGING_DIR"

if [ -d "$PROJECT/garrysmod" ]; then
    # The project contains a full server
    source_dir="$PROJECT/garrysmod"
elif [ -d "$PROJECT/gamemodes" ]; then
    # The project is the contents of a garrysmod/ dir - copy it directly
    :
elif [ -d "$PROJECT/gamemode" ]; then
    # The project is the contents of a gamemode: its name is the first line
    # (quotes stripped) of the keyvalues file containing the word "base"
    gamemode_file="$(cd "$PROJECT" && grep -rlw --exclude-dir=.git --exclude=gluatest-run.log '"base"' . | head -n 1 || true)"
    [ -n "$gamemode_file" ] || err "found gamemode/ but no keyvalues .txt file containing \"base\" - cannot determine the gamemode name"
    gamemode_name="$(head -n 1 "$PROJECT/${gamemode_file#./}" | tr -d '"')"
    [ -n "$gamemode_name" ] || err "could not read a gamemode name from $gamemode_file"
    dest_dir="$STAGING_DIR/gamemodes/$gamemode_name"
elif [ -d "$PROJECT/lua" ]; then
    # The project is an addon
    dest_dir="$STAGING_DIR/addons/project"
else
    err "unrecognized project structure in $PROJECT
Expected one of these at the project root: garrysmod/, gamemodes/, gamemode/, or lua/"
fi

mkdir -p "$dest_dir"
cp -R "$source_dir"/* "$dest_dir/"

# --- Requirements / server cfg: use conventional files if present ---------------
REQUIREMENTS="$PROJECT/gluatest_requirements.txt"
if [ -f "$REQUIREMENTS" ]; then
    note "Using requirements: $REQUIREMENTS"
else
    REQUIREMENTS="$PLACEHOLDER_DIR/requirements.txt"
    touch "$REQUIREMENTS"
fi

CUSTOM_SERVER_CONFIG="$PROJECT/gluatest_custom.cfg"
if [ -f "$CUSTOM_SERVER_CONFIG" ]; then
    note "Using server cfg: $CUSTOM_SERVER_CONFIG"
else
    CUSTOM_SERVER_CONFIG="$PLACEHOLDER_DIR/server.cfg"
    touch "$CUSTOM_SERVER_CONFIG"
fi
if [ -n "$FILTER" ]; then
    filtered_config="$PLACEHOLDER_DIR/filtered-server.cfg"
    cp "$CUSTOM_SERVER_CONFIG" "$filtered_config"
    printf '\ngluatest_filter "%s"\n' "$FILTER" >> "$filtered_config"
    CUSTOM_SERVER_CONFIG="$filtered_config"
fi

# The entrypoint reads artifacts from a nested _gluatest_artifacts/ subdir
mkdir -p "$ARTIFACT_DIR/_gluatest_artifacts"

# --- Env for docker-compose.yml --------------------------------------------------
export GMOD_BRANCH GAMEMODE MAP TIMEOUT COLLECTION_ID
export REQUIREMENTS CUSTOM_SERVER_CONFIG
export PROJECT_DIR="$STAGING_DIR"
export GMOD_ARTIFACT_DIR="$ARTIFACT_DIR"
export SSH_PRIVATE_KEY="${SSH_PRIVATE_KEY:-}"
export GITHUB_TOKEN="${GITHUB_TOKEN:-}"
export EXTRA_STARTUP_ARGS="${EXTRA_STARTUP_ARGS:-}"

HELLO_RUNNER="local"
if [ -n "${AI_AGENT:-}" ]; then
    # "claude-code_2-1-326_agent" -> "agent/claude-code"
    HELLO_RUNNER="agent/${AI_AGENT%%_*}"
elif [ -n "${CLAUDECODE:-}" ]; then
    HELLO_RUNNER="agent/claude-code"
fi
export HELLO_RUNNER

# --- Build or pull -----------------------------------------------------------------
pull_policy="always"
if [ "$BUILD" -eq 1 ]; then
    note "Building the runner image for branch '$GMOD_BRANCH'..."
    docker build --build-arg "GMOD_BRANCH=$GMOD_BRANCH" \
        --tag "ghcr.io/cfc-servers/gluatest/$GMOD_BRANCH:latest" "$SCRIPT_DIR"
    pull_policy="never"
fi

# --- Run --------------------------------------------------------------------------
note "Starting the test server (the first run downloads a multi-GB image and can take a while)..."
log_file="$INVOCATION_DIR/gluatest-run.log"
compose_stream="$PLACEHOLDER_DIR/compose-up.log"
set +e
if [ "$QUIET" -eq 1 ]; then
    "${COMPOSE[@]}" up --pull "$pull_policy" --no-log-prefix --exit-code-from runner > "$compose_stream" 2>&1
else
    "${COMPOSE[@]}" up --pull "$pull_policy" --no-log-prefix --exit-code-from runner
fi
status=$?
set -e

"${COMPOSE[@]}" logs --no-color --no-log-prefix runner > "$log_file" 2>&1 || true
if [ ! -s "$log_file" ] && [ -s "$compose_stream" ]; then
    # compose failed before the container produced output; in quiet mode its
    # stream (with the docker error) is the only record of what went wrong
    cp "$compose_stream" "$log_file"
fi

if [ "$status" -eq 0 ] && [ -n "$FILTER" ]; then
    if grep -q "\[GLuaTest\] Filter .* matched 0 of" "$log_file"; then
        echo "run_local.sh: error: --filter '$FILTER' matched no test groups, so no tests ran." >&2
        status=1
    elif ! grep -q "\[GLuaTest\] Filter .* matched" "$log_file"; then
        note "The GLuaTest version in this runner image does not support --filter, so every test ran."
    fi
fi

if [ "$status" -eq 0 ]; then
    note "Tests passed. Full server log: $log_file"
else
    echo "" >&2
    if [ -s "$log_file" ]; then
        echo "Run failed (exit code $status). Full server log saved to: $log_file" >&2
    else
        # Nothing ran and nothing was captured: the docker error went to the terminal
        rm -f "$log_file"
        echo "Run failed (exit code $status) before the server produced any output - see the docker error above." >&2
    fi
    if [ "$status" -eq 124 ]; then
        echo "The server hit the ${TIMEOUT}-minute time limit before finishing - retry with a higher limit, e.g. --timeout $(( 10#$TIMEOUT * 2 ))." >&2
    fi
fi

notify_if_outdated || true

exit "$status"
