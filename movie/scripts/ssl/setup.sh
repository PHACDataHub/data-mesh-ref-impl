#!/bin/bash

# Exit if encounters non-zero (unsuccessful) status or unset environment variable(s)/parameter(s)
# set -e -u

source .env

# cleanup and create folders
rm -rf ${SECRETS_FOLDER}
mkdir ${SECRETS_FOLDER}

openssl req -new -nodes \
   -x509 \
   -days 365 \
   -newkey rsa:2048 \
   -keyout ${SECRETS_FOLDER}/ca.key \
   -out ${SECRETS_FOLDER}/ca.crt \
   -config conf/ca.cnf

cat ${SECRETS_FOLDER}/ca.crt ${SECRETS_FOLDER}/ca.key > ${SECRETS_FOLDER}/ca.pem

for i in broker broker2 broker3
do
	echo "------------------------------- $i -------------------------------"

    mkdir ${SECRETS_FOLDER}/$i-creds

    # Create server key & certificate signing request(.csr file)
    openssl req -new \
    -newkey rsa:2048 \
    -keyout ${SECRETS_FOLDER}/$i-creds/$i.key \
    -out ${SECRETS_FOLDER}/$i-creds/$i.csr \
    -config conf/$i.cnf \
    -nodes

    # Sign server certificate with CA
    openssl x509 -req \
    -days 3650 \
    -in ${SECRETS_FOLDER}/$i-creds/$i.csr \
    -CA ${SECRETS_FOLDER}/ca.crt \
    -CAkey ${SECRETS_FOLDER}/ca.key \
    -CAcreateserial \
    -out ${SECRETS_FOLDER}/$i-creds/$i.crt \
    -extfile conf/$i.cnf \
    -extensions v3_req

    # Convert server certificate to pkcs12 format
    openssl pkcs12 -export \
    -in ${SECRETS_FOLDER}/$i-creds/$i.crt \
    -inkey ${SECRETS_FOLDER}/$i-creds/$i.key \
    -chain \
    -CAfile ${SECRETS_FOLDER}/ca.pem \
    -name $i \
    -out ${SECRETS_FOLDER}/$i-creds/$i.p12 \
    -password pass:${PASS}

    # Create server keystore
    keytool -importkeystore \
    -deststorepass ${PASS} \
    -destkeystore ${SECRETS_FOLDER}/$i-creds/kafka.$i.keystore.pkcs12 \
    -srckeystore ${SECRETS_FOLDER}/$i-creds/$i.p12 \
    -deststoretype PKCS12  \
    -srcstoretype PKCS12 \
    -noprompt \
    -srcstorepass ${PASS}

    # Save creds
    echo "${PASS}" > ${SECRETS_FOLDER}/${i}-creds/${i}_sslkey_creds
    echo "${PASS}" > ${SECRETS_FOLDER}/${i}-creds/${i}_keystore_creds

done

mkdir ${SECRETS_FOLDER}/client-creds

cp tests/conf/kafka-client.properties ${SECRETS_FOLDER}/client-creds/.

keytool -keystore secrets/client-creds/kafka.client.truststore.pkcs12 \
    -alias CARoot \
    -import \
    -file ${SECRETS_FOLDER}/ca.crt \
    -storepass ${PASS}  \
    -noprompt \
    -storetype PKCS12

echo Security setup completed ✅