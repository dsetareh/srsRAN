#!/bin/bash

if [ $# -ne 2 ]
  then
    echo "Syntax: ./startFuzzing.sh <test start index> <test end index>"
    exit 1
fi

if [ $1 -le 0 ]
  then
    echo "Start Index must be above 0!"
    exit 1
fi

if [ $1 -gt $2 ]
  then
    echo "Start Index cannot be less than End Index!"
    exit 1
fi

echo starting fuzzing using scenarios $1 - $2
sleep 1

for (( i=$1; i<=$2; i++ ))
do
    # contruct header for logs and stdout
    curr_test=$(sed "${i}q;d" decimalFuzz.txt)
    test_header="-------------FUZZ TEST $i ($curr_test)------------------"

    # print to logs and stdout
    echo $test_header
    echo $test_header >> fuzzLogs/epcFuzzLogs.txt
    echo $test_header >> fuzzLogs/enbFuzzLogs.txt
    echo $test_header >> fuzzLogs/epcFuzzLogs.txt

    # start epc, append output to log file, store pid, echo pid
    /home/dsetareh/srsRAN/build/srsepc/src/srsepc >> fuzzLogs/epcFuzzLogs.txt &
    epc_pid=$!
    echo EPC PID: $epc_pid
    sleep 1 # * 1 second wait

    # start enb, append output to log file, store pid, echo pid
    /home/dsetareh/srsRAN/build/srsenb/src/srsenb --rf.device_name=zmq --rf.device_args="fail_on_disconnect=true,tx_port=tcp://*:2000,rx_port=tcp://localhost:2001,id=enb,base_srate=23.04e6" >> fuzzLogs/enbFuzzLogs.txt  &
    enb_pid=$!
    echo ENB PID: $enb_pid
    sleep 1 # * 1 second wait

    # start ue, append output to log file, store pid, echo pid
    /home/dsetareh/srsRAN/build/srsue/src/srsue -f$i >> fuzzLogs/ueFuzzLogs.txt &
    ue_pid=$!
    echo UE  PID: $ue_pid 


    sleep 5 # ! 5 second wait, this is how long the full env lasts before killing begins

    # use stored pid's to kill ue, then enb, then epc
    echo Killing UE
    sleep 1 # * 1 second wait
    kill -KILL $ue_pid
    echo Killing ENB
    sleep 1 # * 1 second wait
    kill -KILL $enb_pid
    echo Killing EPC
    sleep 1 # * 1 second wait
    kill -KILL $epc_pid

    # log competion of iteration, continue
    echo Kills complete, Log written, starting next iteration in 5 seconds...
    sleep 5 # ! 5 second wait
done

echo Fuzzing tests complete!