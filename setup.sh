#  Copyright 2019-2020 JYVSECTEC/Joni Ahonen
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
#  under the License

#! /bin/bash

# Exit if error occur

set -e
#trap "echo $BASH_COMMAND" EXIT

# Allow the script to be executed from various locations

cd "$(dirname "$0")"

# Variable declarations

CHECK="\e[32m[+]\e[0m"
WARNING="\e[33m[!]\e[0m"
ERROR="\e[0;91m[x]\e[0m"
: "${SUBNET:=172.10.0.0/24}"

# Ensure that user has correct privileges to run the script

if [[ $EUID -ne 0 ]]; then
    if [[ ! "$(groups $(whoami))" == *docker* ]]; then
        echo -e "$ERROR Current user $(whoami) is not in docker group or script is not run with root privileges"
        exit
    else
        echo -e "$CHECK Current user is in docker group"
    fi
fi

# Ensure that required packages are installed and can be found from PATH

for VALUE in "docker" "docker-compose" "openssl"; do
    command -v "$VALUE" > /dev/null 2>&1
    echo -e "$CHECK $_ found from PATH"
done

# Ask user input for the network to be used

echo -en "$WARNING "
read -p "Create Docker subnetwork? default: ${SUBNET} [y/N]: " RESPONSE

if [[ "$RESPONSE" =~ ^([yY])$ ]]; then
    echo -en "$WARNING "
    read -p "Give a subnet: " RESPONSE
    if [[ ! -z "$RESPONSE" ]]; then
        NETWORK="${RESPONSE} "
        echo -e "$CHECK Using custom network ${SUBNET}"
    else
        echo -e "$ERROR You must give a correct value"
        echo -e "$WARNING Using default network ${SUBNET}"
    fi
else
    echo -e "$CHECK Using default network ${SUBNET}"
fi

# Set environment variables for Docker Compose

cat <<EOT >.env
PROXY_STATIC_IPv4=$(echo ${SUBNET} | sed "s#0\/.*\$#2#")
WORKER_STATIC_IPv4=$(echo ${SUBNET} | sed "s#0\/.*\$#3#")
FRONT_STATIC_IPv4=$(echo ${SUBNET} | sed "s#0\/.*\$#4#")
ADMIN_STATIC_IPv4=$(echo ${SUBNET} | sed "s#0\/.*\$#5#")
PROMETHEUS_STATIC_IPv4=$(echo ${SUBNET} | sed "s#0\/.*\$#6#")
MYSQL_STATIC_IPv4=$(echo ${SUBNET} | sed "s#0\/.*\$#10#")
NETWORK=${SUBNET}
EOT
echo -e "$CHECK Static IP addresses set."

source .env

# Set the proper environment variables to initialize GRR

cat <<EOT >./env/shared.env
ADMINUI_WEBAUTH_MANAGER=RemoteUserWebAuthManager
ADMINUI_HEADING=JYVSECTEC
CA_CERT=
CA_PRIVATE_KEY=
CSRF_SECRET_KEY=
EXTERNAL_HOSTNAME=${PROXY_STATIC_IPv4}
FRONTEND_CERT=
FRONTEND_PRIVATE_KEY=
FRONTEND_PRIVATE_SIGNING_KEY=
FRONTEND_PUBLIC_SIGNING_KEY=
MYSQL_ROOT_PASSWORD=admin
MYSQL_USER=admin
MYSQL_HOST=${MYSQL_STATIC_IPv4}
MYSQL_PORT=3306
MYSQL_DATABASE=grr
MYSQL_USERNAME=admin
MYSQL_PASSWORD=grr
OSQUERY_PATH_DARWIN="/usr/bin/darwin/osqueryi"
#OSQUERY_PATH_WINDOWS="C:\\Program Files\\osquery\\osqueryi.exe"
OSQUERY_PATH_LINUX="/usr/bin/osqueryi"
REMOTE_TRUSTED_IPV4=${PROXY_STATIC_IPv4}
REMOTE_TRUSTED_IPV6=::ffff:${PROXY_STATIC_IPv4}
EOT

# Generate CSRF unique key

bash scripts/generate-csrf.sh

# Generate certificates and keys for GRR

bash scripts/generate-certs.sh

# Check that the Docker Compose configuration file syntax is correct

docker-compose config > /dev/null 2>&1
echo -e "$CHECK Docker Compose config succeeded."

# Create a self-signed certificate

echo -en "$WARNING "
read -p "Create self-signed certificate? [y/N]: " RESPONSE
if [[ "$RESPONSE" =~ ^([yY])$ ]]; then
    openssl req \
            -newkey rsa:4096 \
            -new \
            -nodes \
            -x509 \
            -days 365 \
            -subj '/CN='${PROXY_STATIC_IPv4}'/O=JYVSECTEC/C=FI' \
            -extensions san \
            -config <(echo "[req]"; echo distinguished_name=req; echo "[san]"; echo subjectAltName=IP:"${PROXY_STATIC_IPv4}") \
            -sha256 \
            -keyout "./nginx/cert.key" \
            -out "./nginx/cert.crt"
    echo -e "$CHECK Self-signed cerficate generated"
else
    echo -e "$CHECK Place certificate and key to the root of nginx directory and name them to cert.crt and cert.key"
fi

# Create nginx default configuration file for GRR

cat <<EOT >./nginx/grr.conf
upstream front {
    server ${FRONT_STATIC_IPv4}:8080;
}

server {
    listen 8080;
    server_name _;
    location / {
        proxy_pass http://front;
    }
}

server {
    listen 80 default_server;
    server_name _;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    ssl_certificate /etc/ssl/certs/cert.crt;
    ssl_certificate_key /etc/ssl/certs/cert.key;
    ssl_session_cache  builtin:1000  shared:SSL:10m;
    ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/grr.access.log;

    location / {
      auth_basic              "restricted site";
      auth_basic_user_file    /etc/nginx/.htpasswd;
      proxy_set_header        X-Remote-User \$remote_user;
      proxy_set_header        Host \$host;
      proxy_set_header        X-Real-IP \$remote_addr;
      proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto \$scheme;

      # Fix the “It appears that your reverse proxy set up is broken" error.
      proxy_pass          http://${ADMIN_STATIC_IPv4}:8000;
      proxy_read_timeout  180;

      proxy_redirect      http://${ADMIN_STATIC_IPv4}:8000 https://${PROXY_STATIC_IPv4};
     }
}
EOT

# Create basic admin/grr user for authentication

{ echo -n 'admin:' & echo -n 'grr' | openssl passwd -apr1 -stdin; } > ./nginx/.htpasswd

# Check if the nginx configuration file syntax is correct

docker pull --quiet nginx:latest
docker run --rm \
            --interactive \
            --tty \
            --volume "$(pwd)/nginx/grr.conf:/etc/nginx/conf.d/default.conf" \
            --volume "$(pwd)/nginx/cert.key:/etc/ssl/certs/cert.key" \
            --volume "$(pwd)/nginx/cert.crt:/etc/ssl/certs/cert.crt" \
            nginx:latest \
            nginx -t
echo -e "$CHECK Nginx configuration syntax check succeeded"

# Create configuration file for prometheus

echo -e "$CHECK Write configuration file for monitoring system"
cat <<EOT >./monitor/prometheus.yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'grr-admin'
    static_configs:
    - targets: ['${ADMIN_STATIC_IPv4}:5005']

  - job_name: 'grr-front'
    static_configs:
    - targets: ['${FRONT_STATIC_IPv4}:5004']

  - job_name: 'grr-worker'
    static_configs:
    - targets: ['${WORKER_STATIC_IPv4}:5003']
EOT

# Inform user

echo -e "$CHECK Setup script completed"
echo -e "$WARNING Use command: 'docker network create --driver=bridge --subnet=${SUBNET} static' to initialize Docker network before you build up the GRR"
