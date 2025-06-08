#!/bin/bash

# Name of the container
CONTAINER_NAME="arch-container"
IMAGE_NAME="arch-image"

# Check if the container exists
if [ $(docker ps -a -q -f name=${CONTAINER_NAME}) ]; then
    echo "Container ${CONTAINER_NAME} exists. Deleting..."
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}
fi

echo "Creating a new ${CONTAINER_NAME}..."

# Pull the latest Arch image
docker pull archlinux:latest

# Build the image from Dockerfile
docker build --tag ${IMAGE_NAME} .

# Run the container
docker run --name ${CONTAINER_NAME} --rm -it ${IMAGE_NAME} bash

echo "Container ${CONTAINER_NAME} created successfully."
