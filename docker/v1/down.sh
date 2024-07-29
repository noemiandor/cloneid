#!/bin/bash

source config.sh

COMPOSE_FILE_NAME="docker-compose.yml"
COMPOSE_PROJECT_NAME=$(basename `pwd`)

if [ ! -z "$1" ]; then
    OPTION=$(echo $1 | tr '[:upper:]' '[:lower:]')
    COMPOSE_FILE_NAME_WITH_OPTION="docker-compose_${OPTION}.yml"
    COMPOSE_FILE_NAME=${COMPOSE_FILE_NAME_WITH_OPTION}
    
    docker compose --file "${COMPOSE_FILE_NAME}" --project-name "${COMPOSE_PROJECT_NAME}" down
    docker system prune -f
fi
