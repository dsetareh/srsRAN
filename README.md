# How to run multiple srsRAN + zmq environments on one machine

## generate namespaces
```
ip netns add ue1
ip netns add ue2
```

## srsepc
```
# srsRAN must be built from this repo for the additional 'abstract' arguments
# they're not handles, but abstract unix pipes, ignore the naming

# unix_abstract_handle_mme must start with an '@'
# unix_abstract_handle_spgw must start with an '@'
# mme.mme_bind_addr and spgw.gtpu_bind_addr are the same ip

# All arguments must be unique to the srsRAN enviroment during runtime


sudo ./srsepc --spgw.unix_abstract_handle_mme @mme_s11  \
              --spgw.unix_abstract_handle_spgw @spgw_s11 \
              --spgw.sgi_if_name srs_spgw_sgi1 \
              --mme.mme_bind_addr 127.1.1.101 \
              --spgw.gtpu_bind_addr 127.1.1.101

sudo ./srsepc --spgw.unix_abstract_handle_mme @mme_s12  \
              --spgw.unix_abstract_handle_spgw @spgw_s12 \
              --spgw.sgi_if_name srs_spgw_sgi2 \
              --mme.mme_bind_addr 127.1.1.103 \
              --spgw.gtpu_bind_addr 127.1.1.103
```

## srsenb
```
# srsENB in this repo is unmodified from upstream (as of right now)

# enb.mme_addr must correspond to epc's spgw.gtpu_bind_addr and mme.mme_bind_addr
# tx_port and rx_port must be unique during runtime

./srsenb --enb.mme_addr 127.1.1.101 \ 
         --rf.device_args "fail_on_disconnect=true,tx_port=tcp://*:2000,rx_port=tcp://localhost:2001,id=enb,base_srate=23.04e6"

./srsenb --enb.mme_addr 127.1.1.103 \ 
         --rf.device_args "fail_on_disconnect=true,tx_port=tcp://*:2002,rx_port=tcp://localhost:2003,id=enb,base_srate=23.04e6"
```

## srsue
```
# srsUE in this repo is modified for our testing, (-f# to test case #)
# tx_port and rx_port must correspond to enb's tx_port and rx_port

./srsue --rf.device_name=zmq \
        --rf.device_args="tx_port=tcp://*:2001,rx_port=tcp://localhost:2000,id=ue,base_srate=23.04e6" \
        --gw.netns=ue1 \
        -f1

./srsue --rf.device_name=zmq \
        --rf.device_args="tx_port=tcp://*:2003,rx_port=tcp://localhost:2002,id=ue,base_srate=23.04e6" \
        --gw.netns=ue2 \
        -f2

```

`dont forget to edit the .confs so that pcaps+logs are saved`