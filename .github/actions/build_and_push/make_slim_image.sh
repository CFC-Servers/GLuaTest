#!/bin/bash
set -eo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../../../docker"

base="ghcr.io/cfc-servers/gluatest/$GMOD_BRANCH"

"$GITHUB_WORKSPACE/docker-slim" build \
    --target gluatest_fat:latest \
    --http-probe-off \
    --env GLUATEST_SLIM_PROBE=true \
    --env HELLO_PROJECT_NAME=gluatest-image-build \
    --continue-after 30 \
    --show-clogs --show-blogs \
    --include-path "/home/steam/gmodserver/garrysmod/addons/gluatest/data_static" \
    --include-path "/home/steam/gmodserver/garrysmod/data" \
    --include-path "/home/steam/.ssh" \
    --preserve-path "/home/steam/gmodserver/garrysmod/cfg/test.cfg" \
    --exclude-pattern "/home/steam/gmodserver/garrysmod/cfg/test.cfg" \
    --include-bin "/usr/bin/date" \
    --include-bin "/usr/bin/git" \
    --include-bin "/usr/bin/tar" \
    --include-bin "/usr/bin/cp" \
    --include-bin "/usr/bin/gzip" \
    --include-bin "/usr/bin/ssh-agent" \
    --include-bin "/usr/bin/ssh-add" \
    --include-bin "/home/steam/gmodserver/bin/libbass.so" \
    --include-bin "/home/steam/gmodserver/bin/linux64/libbass.so" \
    --include-bin "/home/steam/gmodserver/bin/gmod_audio.so" \
    --tag "$base:$TAG_NAME" \
    --tag "$base:gamebuild-$GAME_VERSION"

# "0.27.5" -> "0.27"
# "0.27-pre5" -> "0"
parent_minor_version=${TAG_NAME%.*}
if [[ $parent_minor_version != "0" ]]; then
    echo "::warning:: Tagging with parent minor version: $parent_minor_version"
    docker tag "$base:$TAG_NAME" "$base:$parent_minor_version"
fi

if [ "$RELEASE" = "true" ]; then
    echo "::warning:: Tagging this release as the latest!"
    docker tag "$base:$TAG_NAME" "$base:latest"
fi
