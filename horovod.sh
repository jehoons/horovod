#!/bin/bash 
WHOAMI=$(basename ${HOME})
IMAGE=horovod
IMAGE_FILE=horovod.tar
CONTAINER=horovod-${WHOAMI} 
DOCKER_HOME=/root
HOST_SCRATCH_DIR=${HOME}/.scratch-${IMAGE}
DOCKER_SCRATCH_DIR=${DOCKER_HOME}/.scratch
VOLUMNE_MAPS="-v ${HOST_SCRATCH_DIR}:${DOCKER_SCRATCH_DIR} -v ${HOME}:${DOCKER_HOME}/home"
PORT_MAPS=-P 

# ------------- main ------------
shell(){ 
    docker exec -it ${CONTAINER} su root 
}

push(){ 
    docker push ${IMAGE} 
}

pull(){ 
    docker pull ${IMAGE} 
}

save(){ 
    echo "save image to file ${IMAGE_FILE} ..."
    docker save ${IMAGE} > ${IMAGE_FILE} 
}

ps(){ 
    docker ps | grep --color ${CONTAINER} 
}

build(){ 
    docker build . -t ${IMAGE} 
}

jupyter_address(){
    if [ -e "host.txt" ]
    then # for server setting 
        hostipaddr=$(cat host.txt)
    else 
        hostipaddr="localhost"
    fi 
	jupaddr=$(cat ${HOST_SCRATCH_DIR}/logs/jupyterlab.log | grep -o http://0.0.0.0:8888/.*$ | head -1 | sed "s/0.0.0.0/${hostipaddr}/g")
    jupport=$(docker ps | grep --color ${CONTAINER} | grep -o --color "[0-9]\+->8888\+" | sed "s/->8888//g")
    conn_jupyter=$(echo ${jupaddr} | sed "s/8888/${jupport}/g")
    conn_jupyterlab=$(echo ${conn_jupyter} | sed "s/?/lab?/g")
    echo "Your JupyterLab address is ${conn_jupyterlab}"
    echo "enjoy!"

    echo $conn_jupyterlab > jupyter_connection.info
}

start(){
    mkdir -p ${HOST_SCRATCH_DIR}
    echo "start ${IMAGE}"
    # for gpu-enabled docker 
    docker run --runtime=nvidia --rm -d --name ${CONTAINER} ${PORT_MAPS} ${VOLUMNE_MAPS} ${IMAGE} 
    # for cpu docker 
    # docker run --rm -d --name ${CONTAINER} ${PORT_MAPS} ${VOLUMNE_MAPS} ${IMAGE} 
    if [ $? -eq 0 ]
    then 
        sleep 5
        jupyter_address
    else 
        echo "docker run failed"
    fi 
}

stop(){
	docker stop ${CONTAINER}
}

source $(dirname $0)/argparse.bash || exit 1
argparse "$@" <<EOF || exit 1
parser.description = 'This is a Docker environment for CADD project'
parser.add_argument('mode', type=str, 
    help='shell|push|pull|load|save|build|jup|start|update'
    )

parser.add_argument('-f', '--foreground', 
    action='store_true',
    help='run with foreground mode? [default %(default)s]', 
    default=False
    )

EOF

case "${MODE}" in
    save)
        save
        ;; 
    load)
        load 
        ;; 
    shell)
        shell 
        ;; 
    jup) 
        jupyter_address 
        ;; 
    build)
        build 
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    update)
        build 
        if [ $? -eq 0 ] 
        then 
            echo "wait stoping ..."
            stop 
            wait 
            start
        else 
            echo "build failed"
        fi 
        ;; 
    push)
        push  
        ;;
    pull)
        pull  
        ;;
    *)
        echo 
esac

