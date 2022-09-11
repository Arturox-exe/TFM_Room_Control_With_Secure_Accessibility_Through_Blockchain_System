#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    local PP1=$(one_line_pem $6)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        -e "s#\${PEERPEM1}#$PP1#" \
        -e "s#\${P0PORT1}#$7#" \
        ./ccp-template.json
}

ORG=hospital1
P0PORT=7051
CAPORT=7054
P0PORT1=8051
PEERPEM=../../network/channel/crypto-config/peerOrganizations/hospital1.tfm.com/peers/peer0.hospital1.tfm.com/msp/tlscacerts/tlsca.hospital1.tfm.com-cert.pem
PEERPEM1=../../network/channel/crypto-config/peerOrganizations/hospital1.tfm.com/peers/peer1.hospital1.tfm.com/msp/tlscacerts/tlsca.hospital1.tfm.com-cert.pem
CAPEM=../../network/channel/crypto-config/peerOrganizations/hospital1.tfm.com/msp/tlscacerts/tlsca.hospital1.tfm.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $PEERPEM1 $P0PORT1)" > connection-hospital1.json