FROM jhsong/essential:cuda9.0-cudnn7-devel-ubuntu16.04

MAINTAINER Je-Hoon Song "song.jehoon@gmail.com"

# install basic package 
RUN apt-get update && apt-get install -y cmake-curses-gui
RUN pip install deap scoop

ENV PATH /usr/local/bin:$PATH
ENV PYTHONPATH $PYTHONPATH:/usr/local/lib/python3.5/dist-packages
ENV PS1="\[\033[1;34m\]\!\[\033[0m\] \[\033[1;35m\]HOROVOD\[\033[0m\]:\[\033[1;35m\]\W\[\033[0m\]$ "

RUN echo "export PATH=${PATH}:\$PATH" >> /root/.bashrc
RUN echo "export PS1=\"${PS1}\"" >> /root/.bashrc

# RUN git config --global user.email "song.jehoon@gmail.com"
# RUN git config --global user.name "Je-Hoon Song"

RUN mkdir -p tmp

#######
# torch 
RUN cd /usr/local && git clone https://github.com/torch/distro.git torch --recursive
RUN cd /usr/local/torch && bash install-deps && ./clean.sh && \
	export TORCH_NVCC_FLAGS="-D__CUDA_NO_HALF_OPERATORS__" && \
	./install.sh

#RUN pip3 install http://download.pytorch.org/whl/cu80/torch-0.4.0-cp35-cp35m-manylinux1_x86_64.whl
RUN pip3 install http://download.pytorch.org/whl/cu80/torch-0.4.1-cp35-cp35m-linux_x86_64.whl 

RUN git clone https://github.com/facebook/iTorch.git
RUN pip install 'ipython<6.0'
RUN cd iTorch && /usr/local/torch/install/bin/luarocks make
RUN rm -rf iTorch

# ----------------------
# oddt 
RUN cd tmp && git clone https://github.com/oddt/oddt.git && cd oddt && python setup.py install 
RUN rm -rf tmp

# ----------------------
# networkx
RUN pip install networkx

# ----------------------
# tools for rdkit
RUN pip install CairoSVG

# ----------------------
# deepchem
RUN apt-get update && \
    apt-get install -y -q wget git libxrender1 libsm6 bzip2 && \
    apt-get clean
RUN pip install joblib
RUN mkdir temp && cd temp && \
    git clone https://github.com/deepchem/deepchem.git && cd deepchem && \
    gpu=1 python setup.py install


# for horovod

# ----------------
# Install Open MPI
RUN mkdir /tmp/openmpi && \
    cd /tmp/openmpi && \
    wget https://www.open-mpi.org/software/ompi/v3.1/downloads/openmpi-3.1.2.tar.gz && \
    tar zxf openmpi-3.1.2.tar.gz && \
    cd openmpi-3.1.2 && \
    ./configure --enable-orterun-prefix-by-default && \
    make -j $(nproc) all && \
    make install && \
    ldconfig 
# && rm -rf /tmp/openmpi

# Install Horovod, temporarily using CUDA stubs
# RUN ldconfig /usr/local/cuda-9.0/targets/x86_64-linux/lib/stubs && \
#    HOROVOD_GPU_ALLREDUCE=NCCL HOROVOD_WITH_TENSORFLOW=1 HOROVOD_WITH_PYTORCH=1 pip install --no-cache-dir horovod && ldconfig 

RUN ldconfig /usr/local/cuda-9.0/targets/x86_64-linux/lib/stubs && \
    HOROVOD_GPU_ALLREDUCE=NCCL HOROVOD_WITH_TENSORFLOW=1 pip install horovod --force

# Create a wrapper for OpenMPI to allow running as root by default
#RUN mv /usr/local/bin/mpirun /usr/local/bin/mpirun.real && \
#    echo '#!/bin/bash' > /usr/local/bin/mpirun && \
#    echo 'mpirun.real --allow-run-as-root "$@"' >> /usr/local/bin/mpirun && \
#    chmod a+x /usr/local/bin/mpirun

# Configure OpenMPI to run good defaults:
#   --bind-to none --map-by slot --mca btl_tcp_if_exclude lo,docker0
#RUN echo "hwloc_base_binding_policy = none" >> /usr/local/etc/openmpi-mca-params.conf && \
#    echo "rmaps_base_mapping_policy = slot" >> /usr/local/etc/openmpi-mca-params.conf && \
#    echo "btl_tcp_if_exclude = lo,docker0" >> /usr/local/etc/openmpi-mca-params.conf

# Set default NCCL parameters
#RUN echo NCCL_DEBUG=INFO >> /etc/nccl.conf

# Install OpenSSH for MPI to communicate between containers
#RUN apt-get install -y --no-install-recommends openssh-client openssh-server && \
#    mkdir -p /var/run/sshd

# Allow OpenSSH to talk to containers without asking for confirmation
#RUN cat /etc/ssh/ssh_config | grep -v StrictHostKeyChecking > /etc/ssh/ssh_config.new && \
#    echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config.new && \
#    mv /etc/ssh/ssh_config.new /etc/ssh/ssh_config

# Download examples
#RUN apt-get install -y --no-install-recommends subversion && \
#    svn checkout https://github.com/uber/horovod/trunk/examples && \
#    rm -rf /examples/.svn

VOLUME /root

EXPOSE 8888 

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"] 

CMD ["startup"]

