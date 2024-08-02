#!/bin/bash

DIR0=$(dirname $0)

. ${DIR0}/config.sh

COMPOSE_FILE_NAME="docker-compose.yml"
COMPOSE_PROJECT_NAME=$(basename $(dirname `pwd`))
COMPOSE_PROJECT_NAME=$(basename $DIR0)
COMPOSE_PROJECT_NAME="v1"

if [ ! -z "$1" ]; then
    OPTION=$(echo $1 | tr '[:upper:]' '[:lower:]')
    COMPOSE_FILE_NAME_WITH_OPTION="docker-compose_${OPTION}.yml"
    COMPOSE_FILE_NAME=${COMPOSE_FILE_NAME_WITH_OPTION}
    
    docker compose --file "${DIR0}/v1/Dockerfiles/${COMPOSE_FILE_NAME}" --project-name "${COMPOSE_PROJECT_NAME}" down
    # docker system prune -f
fi
