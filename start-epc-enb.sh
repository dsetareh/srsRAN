#!/bin/bash

/home/dsetareh/srsRAN/build/srsepc/src/srsepc & /home/dsetareh/srsRAN/build/srsenb/src/srsenb --rf.device_name=zmq --rf.device_args="fail_on_disconnect=true,tx_port=tcp://*:2000,rx_port=tcp://localhost:2001,id=enb,base_srate=23.04e6"