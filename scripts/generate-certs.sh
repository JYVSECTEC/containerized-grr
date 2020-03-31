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

# Import env

# Variable declarations

CHECK="\e[32m[+]\e[0m"

# Certificate and key generation

echo "$CHECK Generating certificates and keys"
CA_PRIVATE_KEY=$(openssl genrsa 2048)
CA_CERT=$(openssl req \
        -newkey rsa:2048 \
        -new \
        -nodes \
        -x509 \
        -days 365 \
        -subj '/CN=ca.grr/O=JYVSECTEC/C=FI' \
        -sha256 \
        -key <(echo "$CA_PRIVATE_KEY"))

FRONTEND_PRIVATE_KEY=$(openssl genrsa 2048)
FRONTEND_PRIVATE_SIGNING_KEY=$(openssl genrsa 2048)
FRONTEND_SIGNING_KEY=$(openssl rsa -passin pass: -in <(echo "$FRONTEND_PRIVATE_SIGNING_KEY") -pubout)
FRONTEND_CSR=$(openssl req \
        -new \
        -nodes \
        -key <(echo "$FRONTEND_PRIVATE_KEY") \
        -subj '/CN=front.grr/O=JYVSECTEC/C=FI')
FRONTEND_CERT=$(openssl x509 \
        -req \
        -in <(echo "$FRONTEND_CSR") \
        -CA <(echo "$CA_CERT") \
        -CAkey <(echo "$CA_PRIVATE_KEY") \
        -set_serial 2 \
        -days 365)

CA_PRIVATE_KEY=$(echo -n $CA_PRIVATE_KEY | base64)
CA_CERT=$(echo -n $CA_CERT | base64)
FRONTEND_PRIVATE_KEY=$(echo -n $FRONTEND_PRIVATE_KEY | base64)
FRONTEND_PRIVATE_SIGNING_KEY=$(echo -n $FRONTEND_PRIVATE_SIGNING_KEY | base64)
FRONTEND_SIGNING_KEY=$(echo -n $FRONTEND_SIGNING_KEY | base64)
FRONTEND_CERT=$(echo -n $FRONTEND_CERT | base64)

# Place contents of the variables to the file

echo -e "$CHECK Storing the certificates and keys"
sed -i "s|^CA_PRIVATE_KEY\=.*$|CA_PRIVATE_KEY\=$(echo $CA_PRIVATE_KEY)|" ../env/shared.env
sed -i "s|^CA_CERT\=.*$|CA_CERT\=$(echo $CA_CERT)|" ../env/shared.env
sed -i "s|^FRONTEND_CERT\=.*$|FRONTEND_CERT\=$(echo $FRONTEND_CERT)|" ../env/shared.env
sed -i "s|^FRONTEND_PRIVATE_KEY\=.*$|FRONTEND_PRIVATE_KEY\=$(echo $FRONTEND_PRIVATE_KEY)|" ../env/shared.env
sed -i "s|^FRONTEND_PRIVATE_SIGNING_KEY\=.*$|FRONTEND_PRIVATE_SIGNING_KEY\=$(echo $FRONTEND_PRIVATE_SIGNING_KEY)|" ../env/shared.env
sed -i "s|^FRONTEND_PUBLIC_SIGNING_KEY\=.*$|FRONTEND_PUBLIC_SIGNING_KEY\=$(echo $FRONTEND_SIGNING_KEY)|" ../env/shared.env
