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
  --build              Build the runner image locally instead of pulling the
                       published one (only for hacking on the image itself)
  --quiet              Suppress the live server output; the verdict and exit
                       code still print
  --help               Show this help

Every run writes the full server log to gluatest-run.log in the directory
you invoked from. Exit code 0 = all tests passed; 124 = server hit the
--timeout limit; anything else = test failure or server error.
EOF
}

err() {
    echo "run_local.sh: error: $*" >&2
    exit 1
}

note() {
    echo "==> $*"
}

# --- Flags -------------------------------------------------------------------
PROJECT_DIR_ARG=""
GMOD_BRANCH="public"
GAMEMODE="sandbox"
MAP="gm_construct"
COLLECTION_ID=""
TIMEOUT="2"
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

# --- Preflight ----------------------------------------------------------------
command -v docker > /dev/null 2>&1 || err "docker is not on your PATH.
Install Docker Desktop (macOS / Windows+WSL2) or Docker Engine (Linux): https://docs.docker.com/get-docker/"

docker compose version > /dev/null 2>&1 || err "the Docker Compose plugin is not available ('docker compose version' failed).
Install it: https://docs.docker.com/compose/install/"

docker info > /dev/null 2>&1 || err "the Docker daemon is not reachable ('docker info' failed).
Start Docker Desktop (or the docker service) and try again."

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
    # container_name is fixed (gluatest_runner): a stale container from an
    # interrupted run would break the next one
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
# Unlike CI, deliberately do NOT append "gluatest_github_output 1" to the
# server cfg - local output should stay human-readable.

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

# --- Build or pull -----------------------------------------------------------------
pull_policy="always"
if [ "$BUILD" -eq 1 ]; then
    # compose's `build: .` passes no build args (it would silently bake the
    # default branch into every tag), so build the way CI's dockerbuild path does
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

# Every run leaves the full server log on disk (srcds output is far too spammy
# for terminal scrollback, and agents running this need a file to inspect)
"${COMPOSE[@]}" logs --no-color --no-log-prefix runner > "$log_file" 2>&1 || true
if [ ! -s "$log_file" ] && [ -s "$compose_stream" ]; then
    # compose failed before the container produced output; in quiet mode its
    # stream (with the docker error) is the only record of what went wrong
    cp "$compose_stream" "$log_file"
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

exit "$status"
