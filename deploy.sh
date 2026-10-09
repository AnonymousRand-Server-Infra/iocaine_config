#!/usr/bin/env bash

set -ex

# this makes sure that this script always runs in its own directory so that it pulls
# the right `.env`, for instance (this should also be an absolute path)
script_path="$(dirname "$(realpath "${BASH_SOURCE[0]:-$0}")")"
cd "$script_path"

source ./.env

# try this in our current directory first in case the services to restart were started by
# this project originally
docker compose --profile "$DOCKER_DEFAULT_PROFILE" down

# otherwise (e.g. if they were started by the root docker project), we do a project-agnostic restart
docker stop iocaine && docker rm -v iocaine

docker system prune --force
docker compose --profile "$DOCKER_DEFAULT_PROFILE" up
