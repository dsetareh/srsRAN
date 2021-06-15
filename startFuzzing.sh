#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
GREY='\033[1;30m'
NC='\033[0m'

ENB_LOGFILE="${PWD}/fuzzLogs/enbFuzzLogs.txt"
UE_LOGFILE="${PWD}/fuzzLogs/epcFuzzLogs.txt"
EPC_LOGFILE="${PWD}/fuzzLogs/ueFuzzLogs.txt"
ENB_PCAP_DIR="${PWD}/fuzzLogs/pcap/"

if [ $# -ne 2 ] && [ $# -ne 3 ]
  then
    echo -e "Syntax: ./startFuzzing.sh <test start index> <test end index> <-d> (Optional, to delete existing log files)"
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
    echo -e "${RED}DANGER: DELETION AS ROOT! Ctrl-C within 5 seconds to cancel${NC}"
    sleep 5
    rm -f fuzzLogs/*.txt
    rm -f fuzzLogs/pcap/*.pcap
  else 
    if [ $# -eq 3 ]
    then
      echo "third argument invalid, only -d supported"
      exit 1
    fi
fi

  echo -e "${GREY}UE  Logs stored in ${UE_LOGFILE}"
  echo ENB Logs stored in $ENB_LOGFILE
  echo EPC Logs stored in $EPC_LOGFILE
  echo -e "ENB PCAPs stored in ${ENB_PCAP_DIR}*.pcap${NC}\n"

  sleep 3

  echo -e "Fuzzing using scenarios [$1 - $2]\n"

for (( i=$1; i<=$2; i++ ))
do
    # contruct header for logs and stdout
    curr_test=$(sed "${i}q;d" decimalFuzz.txt)
    test_header="-------------FUZZ TEST $i ($curr_test)------------------"

    # print to logs and stdout
    echo -e "\n${GREEN}$test_header${NC}\n"
    echo $test_header >> fuzzLogs/epcFuzzLogs.txt
    echo $test_header >> fuzzLogs/enbFuzzLogs.txt
    echo $test_header >> fuzzLogs/epcFuzzLogs.txt

    # start epc, append output to log file, store pid, echo pid
    /home/dsetareh/srsRAN/build/srsepc/src/srsepc >> fuzzLogs/epcFuzzLogs.txt &
    epc_pid=$!

    # start enb, append output to log file, store pid, echo pid
    /home/dsetareh/srsRAN/build/srsenb/src/srsenb --rf.device_name=zmq --rf.device_args="fail_on_disconnect=true,tx_port=tcp://*:2000,rx_port=tcp://localhost:2001,id=enb,base_srate=23.04e6" >> fuzzLogs/enbFuzzLogs.txt  &
    enb_pid=$!
    sleep 1 # * 1 second wait

    # start ue, append output to log file, store pid, echo pid
    /home/dsetareh/srsRAN/build/srsue/src/srsue -f$i >> fuzzLogs/ueFuzzLogs.txt &
    ue_pid=$!
    echo -e "${GREEN}STARTING${NC}: UE($ue_pid) - EPC ($epc_pid) - ENB ($enb_pid)\n"


    echo -e "${RED}!!${NC} FUZZING ${RED}!!${NC}\n" # fuzzing must be occuring in the bg
    sleep 3 # ! 3 second wait, this is how long the full env lasts before killing begins

    # use stored pid's to kill ue, then enb, then epc
    echo -e "${RED}STOPPING${NC}: UE($ue_pid) - EPC ($epc_pid) - ENB ($enb_pid)\n"
    kill -KILL $ue_pid
    kill -KILL $enb_pid
    kill -KILL $epc_pid

    echo -e "${GREY}" # kill output is dimmed, as not useful
    sleep 3 # ! 3 second wait
    echo -e "${NC}"

    # save pcap file for enb
    echo -e "\n${GREEN}Saving ENB PCAP as fuzzLogs/pcap/$i.pcap${NC}\n"
    cp enb.pcap fuzzLogs/pcap/$i.pcap

    # log competion of iteration, continue
    echo -e "Test complete, Log written, starting next test in 1 seconds...\n"
    sleep 1 # ! 1 second wait
done

echo Fuzzing tests complete!