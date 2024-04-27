#!/bin/bash

BASE_DIR=$( cd $( dirname $0 ) && pwd -P )
IMAGE_NAME="amazoncorretto:17-alpine-jdk-scouter"
DOCKER_USER="lislroow"
REGISTRY="docker.io"

echo "build ${IMAGE_NAME}"

docker build -t ${IMAGE_NAME} .
docker image tag ${IMAGE_NAME} ${DOCKER_USER}/${IMAGE_NAME}
docker push ${REGISTRY}/${DOCKER_USER}/${IMAGE_NAME}
