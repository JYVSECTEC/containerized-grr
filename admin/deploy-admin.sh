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

# Wait so that the database get initialized to omit unnecessary WARNINGS on logs

echo "###"
echo "###"
echo "###     Waiting database to be initialized"
echo "###"
echo "###"

sleep 10

# Activate virtual environment so that the binaries are usable from PATH

source /usr/share/grr-server/bin/activate

# Initialize GRR server with preset configurations

while IFS= read -r key value; do
    echo -e "$CHECK Updating server configuration"
    grr_config_updater set_var "${key}" "${value}"
done < "/etc/grr/grr-server-alternative.yaml"

# Deploy admin_ui component

grr_server \
    --component admin_ui \
    --disallow_missing_config_definitions
