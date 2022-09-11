export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/network/channel/crypto-config/ordererOrganizations/tfm.com/orderers/orderer.tfm.com/msp/tlscacerts/tlsca.tfm.com-cert.pem
export PEER0_hospital1_CA=${PWD}/network/channel/crypto-config/peerOrganizations/hospital1.tfm.com/peers/peer0.hospital1.tfm.com/tls/ca.crt
export PEER0_hospital2_CA=${PWD}/network/channel/crypto-config/peerOrganizations/hospital2.tfm.com/peers/peer0.hospital2.tfm.com/tls/ca.crt
export PEER0_hospital3_CA=${PWD}/network/channel/crypto-config/peerOrganizations/hospital3.tfm.com/peers/peer0.hospital3.tfm.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/network/channel/config/

export CHANNEL_NAME=mychannel

# setGlobalsForOrderer(){
#     export CORE_PEER_LOCALMSPID="OrdererMSP"
#     export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/network/channel/crypto-config/ordererOrganizations/tfm.com/orderers/orderer.tfm.com/msp/tlscacerts/tlsca.tfm.com-cert.pem
#     export CORE_PEER_MSPCONFIGPATH=${PWD}/network/channel/crypto-config/ordererOrganizations/tfm.com/users/Admin@tfm.com/msp
    
# }

setGlobalsForPeer0hospital1(){
    export CORE_PEER_LOCALMSPID="hospital1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_hospital1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/network/channel/crypto-config/peerOrganizations/hospital1.tfm.com/users/Admin@hospital1.tfm.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

setGlobalsForPeer1hospital1(){
    export CORE_PEER_LOCALMSPID="hospital1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_hospital1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/network/channel/crypto-config/peerOrganizations/hospital1.tfm.com/users/Admin@hospital1.tfm.com/msp
    export CORE_PEER_ADDRESS=localhost:8051
    
}

setGlobalsForPeer0hospital2(){
    export CORE_PEER_LOCALMSPID="hospital2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_hospital2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/network/channel/crypto-config/peerOrganizations/hospital2.tfm.com/users/Admin@hospital2.tfm.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
    
}

setGlobalsForPeer0hospital3(){
    export CORE_PEER_LOCALMSPID="hospital3MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_hospital3_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/network/channel/crypto-config/peerOrganizations/hospital3.tfm.com/users/Admin@hospital3.tfm.com/msp
    export CORE_PEER_ADDRESS=localhost:10051
    
}

createChannel(){
    rm -rf ./channel-artifacts/*
    setGlobalsForPeer0hospital1
    
    peer channel create -o localhost:7050 -c $CHANNEL_NAME \
    --ordererTLSHostnameOverride orderer.tfm.com \
    -f ./network/channel/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
    --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
}

removeOldCrypto(){
    rm -rf ./api-2.0/hospital1-wallet/*
    rm -rf ./api-2.0/hospital2-wallet/*
    rm -rf ./api-2.0/hospital3-wallet/*
}


joinChannel(){
    setGlobalsForPeer0hospital1
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
    setGlobalsForPeer1hospital1
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
    setGlobalsForPeer0hospital2
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
    setGlobalsForPeer0hospital3
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
}

updateAnchorPeers(){
    setGlobalsForPeer0hospital1
    peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.tfm.com -c $CHANNEL_NAME -f ./network/channel/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
    
    setGlobalsForPeer0hospital2
    peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.tfm.com -c $CHANNEL_NAME -f ./network/channel/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
    
    setGlobalsForPeer0hospital3
    peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.tfm.com -c $CHANNEL_NAME -f ./network/channel/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
    
}

removeOldCrypto

createChannel
joinChannel
updateAnchorPeers