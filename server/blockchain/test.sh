export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/network/channel/crypto-config/ordererOrganizations/tfm.com/orderers/orderer.tfm.com/msp/tlscacerts/tlsca.tfm.com-cert.pem
export PEER0_hospital1_CA=${PWD}/network/channel/crypto-config/peerOrganizations/hospital1.tfm.com/peers/peer0.hospital1.tfm.com/tls/ca.crt
export PEER0_hospital2_CA=${PWD}/network/channel/crypto-config/peerOrganizations/hospital2.tfm.com/peers/peer0.hospital2.tfm.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/network/channel/config/

export PRIVATE_DATA_CONFIG=${PWD}/network/private-data/collections_config.json

export CHANNEL_NAME=mychannel

setGlobalsForOrderer() {
    export CORE_PEER_LOCALMSPID="OrdererMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/network/channel/crypto-config/ordererOrganizations/tfm.com/orderers/orderer.tfm.com/msp/tlscacerts/tlsca.tfm.com-cert.pem
    export CORE_PEER_MSPCONFIGPATH=${PWD}/network/channel/crypto-config/ordererOrganizations/tfm.com/users/Admin@tfm.com/msp

}

setGlobalsForPeer0hospital1() {
    export CORE_PEER_LOCALMSPID="hospital1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_hospital1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/network/channel/crypto-config/peerOrganizations/hospital1.tfm.com/users/Admin@hospital1.tfm.com/msp
    # export CORE_PEER_MSPCONFIGPATH=${PWD}/network/channel/crypto-config/peerOrganizations/hospital1.tfm.com/peers/peer0.hospital1.tfm.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

setGlobalsForPeer1hospital1() {
    export CORE_PEER_LOCALMSPID="hospital1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_hospital1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/network/channel/crypto-config/peerOrganizations/hospital1.tfm.com/users/Admin@hospital1.tfm.com/msp
    export CORE_PEER_ADDRESS=localhost:8051

}

setGlobalsForPeer0hospital2() {
    export CORE_PEER_LOCALMSPID="hospital2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_hospital2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/network/channel/crypto-config/peerOrganizations/hospital2.tfm.com/users/Admin@hospital2.tfm.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

}





QueryAssetsByNotification() {
    echo "===================== QueryAssetsByNotification ===================== "
    setGlobalsForPeer0hospital2
    peer chaincode invoke -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.tfm.com \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile $ORDERER_CA \
    -C $CHANNEL_NAME -n ${CC_NAME} \
    --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_hospital1_CA \
    --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_hospital2_CA \
    -c '{"Args":["QueryAssetsByNotification","" ,"", "",""]}'

}




QueryAssetsByNotification
