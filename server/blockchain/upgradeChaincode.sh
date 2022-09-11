export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/artifacts/channel/crypto-config/ordererOrganizations/tfm.com/orderers/orderer.tfm.com/msp/tlscacerts/tlsca.tfm.com-cert.pem
export PEER0_hospital1_CA=${PWD}/artifacts/channel/crypto-config/peerOrganizations/hospital1.tfm.com/peers/peer0.hospital1.tfm.com/tls/ca.crt
export PEER0_hospital2_CA=${PWD}/artifacts/channel/crypto-config/peerOrganizations/hospital2.tfm.com/peers/peer0.hospital2.tfm.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/artifacts/channel/config/

export PRIVATE_DATA_CONFIG=${PWD}/artifacts/private-data/collections_config.json

export CHANNEL_NAME=mychannel

setGlobalsForOrderer() {
    export CORE_PEER_LOCALMSPID="OrdererMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/artifacts/channel/crypto-config/ordererOrganizations/tfm.com/orderers/orderer.tfm.com/msp/tlscacerts/tlsca.tfm.com-cert.pem
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/ordererOrganizations/tfm.com/users/Admin@tfm.com/msp

}

setGlobalsForPeer0hospital1() {
    export CORE_PEER_LOCALMSPID="hospital1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_hospital1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/hospital1.tfm.com/users/Admin@hospital1.tfm.com/msp
    # export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/hospital1.tfm.com/peers/peer0.hospital1.tfm.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

setGlobalsForPeer1hospital1() {
    export CORE_PEER_LOCALMSPID="hospital1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_hospital1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/hospital1.tfm.com/users/Admin@hospital1.tfm.com/msp
    export CORE_PEER_ADDRESS=localhost:8051

}

setGlobalsForPeer0hospital2() {
    export CORE_PEER_LOCALMSPID="hospital2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_hospital2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/hospital2.tfm.com/users/Admin@hospital2.tfm.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

}

setGlobalsForPeer1hospital2() {
    export CORE_PEER_LOCALMSPID="hospital2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_hospital2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/hospital2.tfm.com/users/Admin@hospital2.tfm.com/msp
    export CORE_PEER_ADDRESS=localhost:10051

}

presetup() {
    echo Vendoring Go dependencies ...
    pushd ./artifacts/src/github.com/fabcar/go
    GO111MODULE=on go mod vendor
    popd
    echo Finished vendoring Go dependencies
}
# presetup

CHANNEL_NAME="mychannel"
CC_RUNTIME_LANGUAGE="golang"
VERSION="2"
CC_SRC_PATH="./artifacts/src/github.com/fabcar/go"
CC_NAME="fabcar"

packageChaincode() {
    rm -rf ${CC_NAME}.tar.gz
    setGlobalsForPeer0hospital1
    peer lifecycle chaincode package ${CC_NAME}.tar.gz \
        --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} \
        --label ${CC_NAME}_${VERSION}
    echo "===================== Chaincode is packaged on peer0.hospital1 ===================== "
}
# packageChaincode

installChaincode() {
    setGlobalsForPeer0hospital1
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on peer0.hospital1 ===================== "

    # setGlobalsForPeer1hospital1
    # peer lifecycle chaincode install ${CC_NAME}.tar.gz
    # echo "===================== Chaincode is installed on peer1.hospital1 ===================== "

    setGlobalsForPeer0hospital2
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    echo "===================== Chaincode is installed on peer0.hospital2 ===================== "

    # setGlobalsForPeer1hospital2
    # peer lifecycle chaincode install ${CC_NAME}.tar.gz
    # echo "===================== Chaincode is installed on peer1.hospital2 ===================== "
}

# installChaincode

queryInstalled() {
    setGlobalsForPeer0hospital1
    peer lifecycle chaincode queryinstalled >&log.txt
    cat log.txt
    PACKAGE_ID=$(sed -n "/${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    echo PackageID is ${PACKAGE_ID}
    echo "===================== Query installed successful on peer0.hospital1 on channel ===================== "
}

# queryInstalled

# --collections-config ./artifacts/private-data/collections_config.json \
#         --signature-policy "OR('hospital1MSP.member','hospital2MSP.member')" \
# --collections-config $PRIVATE_DATA_CONFIG \

approveForMyhospital1() {
    setGlobalsForPeer0hospital1
    # set -x
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.tfm.com --tls \
        --collections-config $PRIVATE_DATA_CONFIG \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
        --init-required --package-id ${PACKAGE_ID} \
        --sequence ${VERSION}
    # set +x

    echo "===================== chaincode approved from org 1 ===================== "

}

# approveForMyhospital1

# --signature-policy "OR ('hospital1MSP.member')"
# --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_hospital1_CA --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_hospital2_CA
# --peerAddresses peer0.hospital1.tfm.com:7051 --tlsRootCertFiles $PEER0_hospital1_CA --peerAddresses peer0.hospital2.tfm.com:9051 --tlsRootCertFiles $PEER0_hospital2_CA
#--channel-config-policy Channel/Application/Admins
# --signature-policy "OR ('hospital1MSP.peer','hospital2MSP.peer')"

checkCommitReadyness() {
    setGlobalsForPeer0hospital1
    peer lifecycle chaincode checkcommitreadiness \
        --collections-config $PRIVATE_DATA_CONFIG \
        --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
        --sequence ${VERSION} --output json --init-required
    echo "===================== checking commit readyness from org 1 ===================== "
}

# checkCommitReadyness

# --collections-config ./artifacts/private-data/collections_config.json \
# --signature-policy "OR('hospital1MSP.member','hospital2MSP.member')" \
approveForMyhospital2() {
    setGlobalsForPeer0hospital2

    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.tfm.com --tls $CORE_PEER_TLS_ENABLED \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --collections-config $PRIVATE_DATA_CONFIG \
        --version ${VERSION} --init-required --package-id ${PACKAGE_ID} \
        --sequence ${VERSION}

    echo "===================== chaincode approved from org 2 ===================== "
}

# approveForMyhospital2

checkCommitReadyness() {

    setGlobalsForPeer0hospital1
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_hospital1_CA \
        --collections-config $PRIVATE_DATA_CONFIG \
        --name ${CC_NAME} --version ${VERSION} --sequence ${VERSION} --output json --init-required
    echo "===================== checking commit readyness from org 1 ===================== "
}

# checkCommitReadyness

commitChaincodeDefination() {
    setGlobalsForPeer0hospital1
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.tfm.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --collections-config $PRIVATE_DATA_CONFIG \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_hospital1_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_hospital2_CA \
        --version ${VERSION} --sequence ${VERSION} --init-required

}

# commitChaincodeDefination

queryCommitted() {
    setGlobalsForPeer0hospital1
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME}

}

# queryCommitted

chaincodeInvokeInit() {
    setGlobalsForPeer0hospital1
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.tfm.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_hospital1_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_hospital2_CA \
        --isInit -c '{"Args":[]}'

}

# chaincodeInvokeInit

chaincodeInvoke() {
    # setGlobalsForPeer0hospital1
    # peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.tfm.com \
    # --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} \
    # --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_hospital1_CA \
    # --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_hospital2_CA  \
    # -c '{"function":"initLedger","Args":[]}'

    setGlobalsForPeer0hospital1

    ## Create Car
    # peer chaincode invoke -o localhost:7050 \
    #     --ordererTLSHostnameOverride orderer.tfm.com \
    #     --tls $CORE_PEER_TLS_ENABLED \
    #     --cafile $ORDERER_CA \
    #     -C $CHANNEL_NAME -n ${CC_NAME}  \
    #     --peerAddresses localhost:7051 \
    #     --tlsRootCertFiles $PEER0_hospital1_CA \
    #     --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_hospital2_CA   \
    #     -c '{"function": "createCar","Args":["Car-ABCDEEE", "Audi", "R8", "Red", "Pavan"]}'

    ## Init ledger
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.tfm.com \
        --tls $CORE_PEER_TLS_ENABLED \
        --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_hospital1_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_hospital2_CA \
        -c '{"function": "initLedger","Args":[]}'

    ## Add private data
    export CAR=$(echo -n "{\"key\":\"1111\", \"make\":\"Tesla\",\"model\":\"Tesla A1\",\"color\":\"White\",\"owner\":\"pavan\",\"price\":\"10000\"}" | base64 | tr -d \\n)
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.tfm.com \
        --tls $CORE_PEER_TLS_ENABLED \
        --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_hospital1_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_hospital2_CA \
        -c '{"function": "createPrivateCar", "Args":[]}' \
        --transient "{\"car\":\"$CAR\"}"
}

# chaincodeInvoke

chaincodeQuery() {
    setGlobalsForPeer0hospital2

    # Query all cars
    # peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"Args":["queryAllCars"]}'

    # Query Car by Id
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "queryCar","Args":["CAR0"]}'
    #'{"Args":["GetSampleData","Key1"]}'

    # Query Private Car by Id
    # peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "readPrivateCar","Args":["1111"]}'
    # peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "readCarPrivateDetails","Args":["1111"]}'
}

# chaincodeQuery

# Run this function if you add any new dependency in chaincode
# presetup

packageChaincode
installChaincode
queryInstalled
approveForMyhospital1
checkCommitReadyness
approveForMyhospital2
checkCommitReadyness
commitChaincodeDefination
queryCommitted
chaincodeInvokeInit
sleep 5
chaincodeInvoke
sleep 3
chaincodeQuery
