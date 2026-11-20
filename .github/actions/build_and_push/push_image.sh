#!/bin/bash
set -eo pipefail

docker push "ghcr.io/cfc-servers/gluatest/$GMOD_BRANCH" --all-tags
