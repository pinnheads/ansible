# Builds a docker image for a ubuntu system
# Run docker build - < Dockerfile 
# docker build --tag <image name> .
# docker run --rm -it <image name> bash

FROM ubuntu:focal AS base
WORKDIR /usr/local/bin
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y software-properties-common curl git build-essential && \
    apt-add-repository -y ppa:ansible/ansible && \
    apt-get update && \
    apt-get install -y curl git ansible build-essential && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    apt-get install nano && \
    apt-get install git && git config --global user.email "utsavdeep01@gmail.com" && git config --global user.name "Utsav"
