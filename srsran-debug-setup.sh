#!/bin/bash

# Build script for srsRAN debugging environment

# update
sudo apt update
sudo apt upgrade

# install prereqs
sudo apt install git \
                 build-essential \
                 cmake \
                 libfftw3-dev \
                 libmbedtls-dev \
                 libboost-program-options-dev \
                 libconfig++-dev \
                 libsctp-dev \
                 libzmq3-dev    # for zeroMQ


# create and enter build/ directory
mkdir build
cd build

# build srsRAN with debugging symbols
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ../
make

# create new network namespace for UE
sudo ip netns add ue1

# run tests to verify build success
make test

# copies default srsRAN configs to user directories
sudo srsran_install_configs.sh user

