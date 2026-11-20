#!/bin/bash
set -eo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../../../docker"

docker build \
    --build-arg="GMOD_BRANCH=$GMOD_BRANCH" \
    --build-arg="GLUATEST_REF=$TAG_NAME" \
    --tag gluatest_fat:latest .
