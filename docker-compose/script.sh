#!/bin/bash

set -e

export DB_ROOT_PASS=changeme
export DB_NAME=drupal-db
export DB_USER=drupal-db-user
export DB_PASS=changeme

function usage() {
    echo "Start up or tear down the docker-compose stack."
    echo ""
    echo "$0 [CMD]"
    echo ""
    echo "CMDs:"
    echo "  help"
    echo "  up                  Start up the docker-compose stack"
    echo "  down                Tear down the docker-compose stack"
    echo ""
}

function up() {
    docker-compose up
}

function down() {
    docker-compose down
}

case $1 in
    help)
        usage
        exit
        ;;
    up)
        up
        ;;
    down)
        down
        ;;
    *)
        echo "ERROR: unknown cmd \"$1\""
        usage
        exit 1
        ;;
esac
