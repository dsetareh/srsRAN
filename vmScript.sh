apt update && apt -y upgrade
apt install -y build-essential cmake libfftw3-dev libmbedtls-dev libboost-program-options-dev libconfig++-dev libsctp-dev libzmq3-dev
git clone https://github.com/dsetareh/srsRAN
ip netns add ue1
cd srsRAN
mkdir fuzzLogs
mkdir fuzzLogs/pcap
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ../
make
cd ..
tar xvf currConfs.tar
cd currconf/
mkdir /etc/srsran
cp ./* /etc/srsran/