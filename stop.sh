#!/usr/bin/env bash

set -ex

# this makes sure that this script always runs in its own directory so that it pulls
# the right `.env`, for instance (this should also be an absolute path)
script_path="$(dirname "$(realpath "${BASH_SOURCE[0]:-$0}")")"
cd "$script_path"

set +e
source ./.env
set -e
path_to_utils="$PATH_TO_SERVER_ROOT/$PATH_FROM_ROOT_TO_UTILS"

# still need this for `docker compose down` to succeed
chmod +x "$path_to_utils/sync_dotenvs.sh" && "$path_to_utils/sync_dotenvs.sh"

# try this in our current directory first in case the services to stop were started by
# this project originally
docker compose --profile "$DOCKER_DEFAULT_PROFILE" down

# otherwise (e.g. if they were started by the root docker project), we do a project-agnostic stop
# SYNC: containers and depended on containers!
source "$path_to_utils/bash_utils.sh"
errorless_docker_down iocaine
