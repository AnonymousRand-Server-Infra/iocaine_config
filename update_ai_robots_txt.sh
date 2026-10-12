#!/usr/bin/env bash

set -ex

# this makes sure that this script always runs in its own directory so that the
# relative paths here are correct
script_path="$(dirname "$(realpath "${BASH_SOURCE[0]:-$0}")")"
cd "$script_path"

# SYNC
path_to_ai_robots_txt=./data/ai.robots.txt-robots.json

source ./.env

sudo -u "#$HOST_NONROOT_UID" \
    curl -L https://github.com/ai-robots-txt/ai.robots.txt/raw/refs/heads/main/robots.json \
    -o "$path_to_ai_robots_txt"

chmod +x ./deploy.sh
# `-d` to make sure the output of this script doesn't continue forever and prevent us from moving on
./deploy.sh -d

sudo -u "$GIT_USER" bash -c "
    git add \"$path_to_ai_robots_txt\"
    # since we have `set -e`, we need to not commit if nothing was changed, as that exits with error
    git diff-index --quiet HEAD || git commit -m '[autocommit] update ai robots list'
    git push
"
