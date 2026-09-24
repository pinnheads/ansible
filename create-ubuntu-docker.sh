#!/bin/bash

# Name of the container
CONTAINER_NAME="ubuntu-noble-container"
IMAGE_NAME="ubuntu-noble-image"

# Check if the container exists
if [ $(docker ps -a -q -f name=${CONTAINER_NAME}) ]; then
	echo "Container ${CONTAINER_NAME} exists. Deleting..."
	# Stop the container if it is running
	docker stop ${CONTAINER_NAME}
	# Remove the container
	docker rm ${CONTAINER_NAME}
fi

echo "Creating a new ${CONTAINER_NAME}..."

# Pull the latest Ubuntu LTS image (if not already pulled)
docker pull ubuntu:noble

# Create a new build image
docker build - <Dockerfile

# Create container
docker build --tag ${IMAGE_NAME} .

# Run Container
docker run --name ${CONTAINER_NAME} --rm -it ${IMAGE_NAME} bash

echo "Container ${CONTAINER_NAME} created successfully."
