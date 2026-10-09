#!/usr/bin/env bash

set -ex

curl -L https://github.com/ai-robots-txt/ai.robots.txt/raw/refs/heads/main/robots.json \
    -o data/ai.robots.txt-robots.json

chmod +x ./deploy.sh
./deploy.sh
