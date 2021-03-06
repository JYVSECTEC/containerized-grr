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

# Allow the script to be executed from various locations

cd "$(dirname "$0")"

# Copy configuration file to the correct subdirectories

echo "../admin ../worker ../front" | xargs -n 1 cp -v ../config.yaml
