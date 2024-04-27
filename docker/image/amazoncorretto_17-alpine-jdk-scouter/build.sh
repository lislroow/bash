#!/bin/bash

docker build -t amazoncorretto:17-alpine-jdk-scouter .
docker image tag amazoncorretto:17-alpine-jdk-scouter lislroow/amazoncorretto:17-alpine-jdk-scouter
docker push docker.io/lislroow/amazoncorretto:17-alpine-jdk-scouter
