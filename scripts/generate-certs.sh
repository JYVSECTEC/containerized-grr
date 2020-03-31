#  Copyright 2019-2020 JYVSECTEC/Joni Ahonen
#
#  Copyright 2018-2019 Spotify AB.
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#      http://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing,
#  software distributed under the License is distributed on an
#  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied.  See the License for the
#  specific language governing permissions and limitations
#  under the License.

#! /bin/bash

# Exit if error occur

set -e

# Allow the script to be executed from various locations

cd "$(dirname "$0")"

# Variable declarations

CHECK="\e[32m[+]\e[0m"

# Create directory for files if does not exists

if [ ! -d openssl ]; then
        mkdir openssl
fi

# Certificate and key generation

echo "$CHECK Generating certificates and keys"
openssl genrsa -out openssl/ca-private.key 2048
openssl req \
        -newkey rsa:2048 \
        -new \
        -nodes \
        -x509 \
        -days 365 \
        -subj '/CN=ca.grr/O=JYVSECTEC/C=FI' \
        -sha256 \
        -key openssl/ca-private.key \
        -out openssl/ca.crt

openssl genrsa -out openssl/front-end-private.key 2048
openssl genrsa -out openssl/front-end-private-signing.key 2048
openssl rsa -passin pass: -in openssl/front-end-private-signing.key -pubout -out openssl/front-end-signing.key
openssl req \
        -new \
        -nodes \
        -key openssl/front-end-private.key \
        -subj '/CN=front.grr/O=JYVSECTEC/C=FI' \
        -out openssl/front-end.csr
openssl x509 \
        -req \
        -in openssl/front-end.csr \
        -CA openssl/ca.crt \
        -CAkey openssl/ca-private.key \
        -set_serial 2 \
        -days 365 \
        -out openssl/front-end.crt

base64 -w0 openssl/ca-private.key > openssl/enc-ca.key
base64 -w0 openssl/ca.crt > openssl/enc-ca.crt
base64 -w0 openssl/front-end.crt > openssl/enc-front-end.crt
base64 -w0 openssl/front-end-private.key > openssl/enc-front-end-private.key
base64 -w0 openssl/front-end-signing.key > openssl/enc-front-end-private-signing.key
base64 -w0 openssl/front-end-signing.key > openssl/enc-front-end-signing.key

# Declare the environment variables with the contents of the files

echo -e "$CHECK Storing the certificates and keys"
sed -i "s|^CA_PRIVATE_KEY\=.*$|CA_PRIVATE_KEY\=$(cat openssl/enc-ca.key)|" ../env/shared.env
sed -i "s|^CA_CERT\=.*$|CA_CERT\=$(cat openssl/enc-ca.crt)|" ../env/shared.env
sed -i "s|^FRONTEND_CERT\=.*$|FRONTEND_CERT\=$(cat openssl/enc-front-end.crt)|" ../env/shared.env
sed -i "s|^FRONTEND_PRIVATE_KEY\=.*$|FRONTEND_PRIVATE_KEY\=$(cat openssl/enc-front-end-private.key)|" ../env/shared.env
sed -i "s|^FRONTEND_PRIVATE_SIGNING_KEY\=.*$|FRONTEND_PRIVATE_SIGNING_KEY\=$(cat openssl/enc-front-end-private-signing.key)|" ../env/shared.env
sed -i "s|^FRONTEND_PUBLIC_SIGNING_KEY\=.*$|FRONTEND_PUBLIC_SIGNING_KEY\=$(cat openssl/enc-front-end-signing.key)|" ../env/shared.env
