#!/bin/bash
set -eo pipefail

SLIM_VERSION=1.40.11

curl --location --output ds.tar.gz "https://github.com/slimtoolkit/slim/releases/download/$SLIM_VERSION/dist_linux.tar.gz"
tar -xvzf ds.tar.gz
mv dist_linux/* "$GITHUB_WORKSPACE"
rm -rfv ds.tar.gz dist_linux/

docker version
