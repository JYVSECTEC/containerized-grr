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

# Pin to tested version number
FROM grrdocker/grr:v3.3.0.8

# EXPOSE 5004

ENV MONITORING_HTTP_PORT=5004
ENV CERTS_PATH=/etc/grr/certs
ENV FRONTEND_CERT_PATH=$CERTS_PATH/frontend-cert.pem
ENV FRONTEND_PRIVATE_KEY_PATH=$CERTS_PATH/frontend-private.key
ENV FRONTEND_PRIVATE_SIGNING_KEY_PATH=$CERTS_PATH/frontend-signing.key
ENV FRONTEND_PUBLIC_SIGNING_KEY_PATH=$CERTS_PATH/frontend-signing.pub
ENV CA_CERT_PATH=$CERTS_PATH/ca-cert.pem
ENV CA_PRIVATE_KEY_PATH=$CERTS_PATH/ca-private.key

RUN mkdir -p $CERTS_PATH

COPY ./front/prepare-certs.sh $GRR_VENV/bin/prepare-certs.sh
COPY ./front/deploy-front.sh $GRR_VENV/bin/deploy-front.sh
COPY ./front/repack-clients.sh $GRR_VENV/bin/repack-clients.sh

CMD $GRR_VENV/bin/prepare-certs.sh && \
	$GRR_VENV/bin/repack-clients.sh && \
	$GRR_VENV/bin/deploy-front.sh
