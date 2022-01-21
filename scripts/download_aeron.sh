#!/bin/bash

# Strict mode
set -euo pipefail

# variables
SCRIPT_DIR=$(dirname "$(realpath $0)")

# Load environment variables
export $(cat ${SCRIPT_DIR}/.env | xargs)

# Make bin directory
mkdir -p ${SCRIPT_DIR}/bin

# Download JAR
curl -L https://search.maven.org/remotecontent?filepath=io/aeron/aeron-all/${AERON_VERSION}/aeron-all-${AERON_VERSION}.jar --output ${SCRIPT_DIR}/bin/aeron-all.jar
