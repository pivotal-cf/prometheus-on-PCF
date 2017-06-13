#!/bin/bash
set -e
CURL="om --target https://${opsman_url} -k \
  --username $pcf_opsman_admin_username \
  --password $pcf_opsman_admin_password \
  curl"

if [ -z "$pcf_bosh_director_hostname" ]; then
  director_uri=$(cat om-bosh-creds/director_ip)
else
  director_uri=${pcf_bosh_director_hostname}
fi

if [[ -s om-bosh-creds/bosh-ca.pem ]]; then
  bosh -n --ca-cert om-bosh-creds/bosh-ca.pem target ${director_uri}
else
  bosh -n target `cat om-bosh-creds/director_ip`
fi

BOSH_USERNAME=$(cat om-bosh-creds/bosh-username)
BOSH_PASSWORD=$(cat om-bosh-creds/bosh-pass)

echo "Logging in to BOSH..."
bosh login <<EOF 1>/dev/null
$BOSH_USERNAME
$BOSH_PASSWORD
EOF

echo "Interpolating..."
eval "echo \"$(cat pcf-prometheus-git/pipeline/tasks/etc/local.yml)\"" > local.yml
bosh-cli interpolate pcf-prometheus-git/prometheus.yml -l local.yml > manifest.yml

echo "Deploying..."

bosh -n deployment manifest.yml

bosh -n deploy --no-redact
