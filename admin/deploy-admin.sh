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
#  under the License

#! /bin/bash

# Exit if error occur

set -e

# Variable definitions

CHECK="\e[32m[+]\e[0m"

# Inform user

echo "###"
echo "###"
echo "###     GRR ADMIN COMPONENT CONTAINER IS ABOUT TO BE STARTED"
echo "###"
echo "###"

# Wait database to be initialized

sleep 20

# Activate virtual environment so that the executables are usable from PATH

echo -e "$CHECK Activate Python virtual environment"
source /usr/share/grr-server/bin/activate

# Use 'grr_config_updater set_var' to place certificates and keys as raw values
# See issue https://github.com/google/grr/issues/646

echo -e "$CHECK Write raw certificate data to configuration file"
grr_config_updater set_var Client.executable_signing_public_key "$(cat $FRONTEND_PUBLIC_SIGNING_KEY_PATH)" -p "Config.writeback=/etc/grr/server.local.yaml"
grr_config_updater set_var PrivateKeys.executable_signing_private_key "$(cat $FRONTEND_PRIVATE_SIGNING_KEY_PATH)" -p "Config.writeback=/etc/grr/server.local.yaml"
grr_config_updater set_var Frontend.certificate "$(cat $FRONTEND_CERT_PATH)" -p "Config.writeback=/etc/grr/server.local.yaml"
grr_config_updater set_var PrivateKeys.server_key "$(cat $FRONTEND_PRIVATE_KEY_PATH)" -p "Config.writeback=/etc/grr/server.local.yaml"
grr_config_updater set_var CA.certificate "$(cat $CA_CERT_PATH)" -p "Config.writeback=/etc/grr/server.local.yaml"
grr_config_updater set_var PrivateKeys.ca_key "$(cat $CA_PRIVATE_KEY_PATH)" -p "Config.writeback=/etc/grr/server.local.yaml"

# Deploy admin_ui component

echo -e "$CHECK Start the admin_ui component"
grr_admin_ui \
    --disallow_missing_config_definitions
