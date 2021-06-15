#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'


if [ $# -ne 2 ] && [ $# -ne 3 ]
  then
    echo -e "Syntax: ./startFuzzing.sh <test start index> <test end index> <-d> (Optional, to delete existing log files)\n"
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

if [ $# -eq 3 ] && [ $3 == "-d" ]
  then
    echo -e "${RED}Deleting prior log files...${NC}"
    rm -f fuzzLogs/*.txt
  else 
    if [ $# -eq 3 ]
    then
      echo "third argument invalid, only -d supported"
      exit 1
    fi
fi

    echo Starting fuzzing using scenarios $1 - $2...
    sleep 3

for (( i=$1; i<=$2; i++ ))
do
    # contruct header for logs and stdout
    curr_test=$(sed "${i}q;d" decimalFuzz.txt)
    test_header="${GREEN}-------------FUZZ TEST $i ($curr_test)------------------${NC}\n"

    # print to logs and stdout
    echo -e $test_header
    echo -e $test_header >> fuzzLogs/epcFuzzLogs.txt
    echo -e $test_header >> fuzzLogs/enbFuzzLogs.txt
    echo -e $test_header >> fuzzLogs/epcFuzzLogs.txt

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


    echo -e "\n${RED}!!${NC} FUZZING ${RED}!!${NC}\n"
    sleep 5 # ! 5 second wait, this is how long the full env lasts before killing begins

    # use stored pid's to kill ue, then enb, then epc
    echo Killing UE ($ue_pid), ENB ($enb_pid), EPC ($epc_pid)
    kill -KILL $ue_pid
    kill -KILL $enb_pid
    kill -KILL $epc_pid

    sleep 6 # ! 6 second wait

    # save pcap file for enb
    echo -e "${GREEN}Saving ENB PCAP as fuzzLogs/pcap/$i.pcap${NC}\n"
    cp enb.pcap fuzzLogs/pcap/$i.pcap
    sleep 3 # ! 3 second wait

    # log competion of iteration, continue
    echo -e "${GREEN}Test complete, Log written, starting next test in 5 seconds...${NC}\n"
    sleep 5 # ! 5 second wait
done

echo Fuzzing tests complete!