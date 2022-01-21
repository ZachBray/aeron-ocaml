#!/bin/bash

# Strict mode
set -euo pipefail

# Docs
echo
echo Prerequisites:
echo   - ./download_aeron.sh
echo   - ./run_media_driver.sh
echo

# variables
SCRIPT_DIR=$(dirname "$(realpath $0)")
PROJECT_DIR=${SCRIPT_DIR}/..

# Load environment variables
export $(cat ${SCRIPT_DIR}/.env | xargs)

# Run media driver
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${PROJECT_DIR}/_build/default/lib ${PROJECT_DIR}/_build/default/examples/basic_subscriber/basic_subscriber.exe
