#!/bin/bash

curl -L "https://download.demisto.com/download-params?token=$2&email=$3&eula=accept" > demisto.sh
chmod +x demisto.sh

sudo ./demisto.sh -- -y -do-not-start-server

sudo cp /tmp/secrets/otc.conf.json /var/lib/demisto/
sudo chown demisto:demisto /var/lib/demisto/otc.conf.json
sudo service demisto start

PUBLIC_IP=$(curl checkip.amazonaws.com)

# Wait for server to be available
sleep 120

# Apply the license file
curl -F file=@/tmp/secrets/license.lic "https://${PUBLIC_IP}/license/upload" -H 'content-type: multipart/form-data' -H 'accept: application/json' -H "Authorization: $1" --insecure

echo "#### XSOAR Details ####"
echo "Public IP: ${PUBLIC_IP}"
