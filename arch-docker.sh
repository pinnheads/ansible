#!/bin/bash

# Name of the container
CONTAINER_NAME="arch-container"
IMAGE_NAME="arch-image"

# Get the project root directory
PROJECT_ROOT=$(git rev-parse --show-toplevel)

# Check if the container exists
if [ $(docker ps -a -q -f name=${CONTAINER_NAME}) ]; then
    echo "Container ${CONTAINER_NAME} exists. Deleting..."
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}
fi

echo "Creating a new ${CONTAINER_NAME}..."

# Build the image from Dockerfile (run from the directory containing the Dockerfile)
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
docker build -t ${IMAGE_NAME} "${SCRIPT_DIR}"

# Run the container with the project root mounted
docker run --name ${CONTAINER_NAME} \
    --rm -it \
    -v "${PROJECT_ROOT}:/home/utsav/ansible" \
    -w /home/utsav/ansible \
    ${IMAGE_NAME} bash

echo "Container ${CONTAINER_NAME} created successfully."
