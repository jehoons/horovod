#!/bin/bash -eu
cmd="$1"
if [ "${cmd}" == "startup" ]; then
    echo "###########################"
    echo "#      Jupyter lab"
    echo "###########################"
    export SHELL=/bin/bash
    mkdir -p .scratch/logs
    juplog=.scratch/logs/jupyterlab.log
    jupyter lab --port=8888 --no-browser --ip=0.0.0.0 --allow-root --notebook-dir=`pwd` >& ${juplog} & 
    sleep 1
    tail -f ${juplog}
else
    exec "$@"
fi
