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

# This script is a Bourne Again Shell implementation of the GRR development team's original source code written in Python 2.7
# Script generates an unique CSRF key that is required for GRR user interface configuration
# https://github.com/google/grr/blob/a4e4179d9be01d0c85af9fbf0c94ccfb5f42c665/grr/core/grr_response_core/lib/utils.py#L691
# https://github.com/google/grr/blob/2c1e6fce9ea0db9285b5b909b72b0778c677b9a5/grr/server/grr_response_server/bin/config_updater_keys_util.py#L26

# Exit if error occur

set -e

# Allow script to be executed from various locations

cd "$(dirname "$0")"

# Variable definitions

CHECK="\e[32m[+]\e[0m"
LENGTH=100
UNIQUE_CSRF_KEY=$(</dev/urandom tr -dc 'A-Za-z0-9-,_&$#' | head -c ${LENGTH})

# Replace with unique CSRF key

sed -i "s|^CSRF_SECRET_KEY\=.*$|CSRF_SECRET_KEY\=$(printf '%q\n' $UNIQUE_CSRF_KEY)|" ../env/shared.env

echo -e "$CHECK Unique CSRF key generated and placed"