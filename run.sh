#!/bin/bash
#
# Zcash node manager
# Released under GNU AGPL by Someguy123
#

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_DIR="$DIR/dkr"
DATADIR="$DIR/data"
DOCKER_NAME="zcash"

BOLD="$(tput bold)"
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
BLUE="$(tput setaf 4)"
MAGENTA="$(tput setaf 5)"
CYAN="$(tput setaf 6)"
WHITE="$(tput setaf 7)"
RESET="$(tput sgr0)"

# default. override in .env
PORTS="8233"

if [[ -f .env ]]; then
    source .env
fi

if [[ ! -f data/zcash.conf ]]; then
    echo "config.ini not found. copying example";
    cp $DATADIR/zcash.example.conf $DATADIR/zcash.conf
fi

IFS=","
DPORTS=""
for i in $PORTS; do
    if [[ $i != "" ]]; then
         if [[ $DPORTS == "" ]]; then
            DPORTS="-p0.0.0.0:$i:$i"
        else
            DPORTS="$DPORTS -p0.0.0.0:$i:$i"
        fi
    fi
done

help() {
    echo "Usage: $0 COMMAND [DATA]"
    echo
    echo "Commands: "
    echo "    start - starts zcash container"
    echo "    stop - stops zcash container"
    echo "    status - show status of zcash container"
    echo "    restart - restarts zcash container"
    echo "    install - pulls latest docker image from server (no compiling)"
    echo "    rebuild - builds zcash container (from docker file), and then restarts it"
    echo "    build - only builds zcash container (from docker file)"
    echo "    logs - show all logs inc. docker logs, and zcash logs"
    echo "    enter - enter a bash session in the container"
    echo
    exit
}

build() {
    echo $GREEN"Building docker container"$RESET
    cd $DOCKER_DIR
    docker build -t zcash .
}

install() {
    # step 1, get rid of old zcash
    echo "Stopping and removing any existing zcash containers"
    docker stop zcash
    docker rm zcash
    echo "Loading image from someguy123/zcash"
    docker pull someguy123/zcash
    echo "Tagging as zcash"
    docker tag someguy123/zcash zcash
    echo "Installation completed. You may now configure or run the server"
}

seed_exists() {
    seedcount=$(docker ps -a -f name="^/"$DOCKER_NAME"$" | wc -l)
    if [[ $seedcount -eq 2 ]]; then
        return 0
    else
        return -1
    fi
}

seed_running() {
    seedcount=$(docker ps -f 'status=running' -f name=$DOCKER_NAME | wc -l)
    if [[ $seedcount -eq 2 ]]; then
        return 0
    else
        return -1
    fi
}

start() {
    echo $GREEN"Starting container..."$RESET
    seed_exists
    if [[ $? == 0 ]]; then
        docker start $DOCKER_NAME
    else
        docker run $DPORTS -v "$DATADIR":/root/.zcash -d --name $DOCKER_NAME -t zcash
    fi
}

stop() {
    echo $RED"Stopping container..."$RESET
    docker stop $DOCKER_NAME
}

enter() {
    docker exec -it $DOCKER_NAME bash
}

logs() {
    echo $BLUE"DOCKER LOGS: "$RESET
    docker logs --tail=30 $DOCKER_NAME
    #echo $RED"INFO AND DEBUG LOGS: "$RESET
    tail -n 30 $DATADIR/debug.log
}

status() {
    
    seed_exists
    if [[ $? == 0 ]]; then
        echo "Container exists?: "$GREEN"YES"$RESET
    else
        echo "Container exists?: "$RED"NO (!)"$RESET 
        echo "Container doesn't exist, thus it is NOT running. Run $0 build && $0 start"$RESET
        return
    fi

    seed_running
    if [[ $? == 0 ]]; then
        echo "Container running?: "$GREEN"YES"$RESET
    else
        echo "Container running?: "$RED"NO (!)"$RESET
        echo "Container isn't running. Start it with $0 start"$RESET
        return
    fi

}

if [ "$#" -ne 1 ]; then
    help
fi

case $1 in
    build)
        echo "You may want to use '$0 install' for a binary image instead, it's faster."
        build
        ;;
    install)
        install
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 5
        start
        ;;
    rebuild)
        stop
        sleep 5
        build
        start
        ;;
    status)
        status
        ;;
    enter)
        enter
        ;;
    logs)
        logs
        ;;
    *)
        echo "Invalid cmd"
        help
        ;;
esac
