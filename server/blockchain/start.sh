rm channel-artifacts/mychannel.block

docker-compose -f ./network/docker-compose.yaml up -d

sleep 10
./createChannel.sh

sleep 5

./deployRegistryChaincode.sh