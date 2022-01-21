#!/bin/bash

# Strict mode
set -euo pipefail

# Docs
echo
echo Prerequisites:
echo   - ./download_aeron.sh
echo

# variables
SCRIPT_DIR=$(dirname "$(realpath $0)")

# Load environment variables
export $(cat ${SCRIPT_DIR}/.env | xargs)

# Run media driver
java -cp ${SCRIPT_DIR}/bin/aeron-all.jar -Daeron.dir=${AERON_DIR} io.aeron.driver.MediaDriver
