#!/usr/bin/env bash

set -e

curl -L https://github.com/ai-robots-txt/ai.robots.txt/raw/refs/heads/main/robots.json \
       -o data/ai.robots.txt-robots.json
systemctl restart iocaine
