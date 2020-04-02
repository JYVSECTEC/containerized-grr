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

# Variable definitions

CHECK="\e[32m[+]\e[0m"

# Inform user

echo "###"
echo "###"
echo "###     GRR FRONT COMPONENT CONTAINER IS ABOUT TO BE STARTED"
echo "###"
echo "###"

# Activate virtual environment so that the executables are usable from PATH

echo -e "$CHECK Activate Python virtual environment"
source /usr/share/grr-server/bin/activate

# Deploy frontend component

echo -e "$CHECK Start the frontend component"
grr_frontend \
    --disallow_missing_config_definitions
