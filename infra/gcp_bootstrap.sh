#!/bin/bash
# ExoTalk GCP Bootstrap (Infrastructure Launch)

# 1. Authenticate
# --- SDK STRATEGY ---
# We keep the 1GB Google Cloud SDK outside the monorepo root to maintain
# workspace cleanliness. This dynamic path resolves to the parent directory.
GCLOUD="$(cd "$(dirname "$0")/../../google-cloud-sdk/bin" && pwd)/gcloud"
$GCLOUD auth activate-service-account --key-file="$(dirname "$0")/deploy-key.json"
$GCLOUD config set project gen-lang-client-0135693111 --quiet

# 2. Configure Project
PROJECT_ID=$($GCLOUD config get-value project)
echo "Launching Relay in project: $PROJECT_ID"

# 3. Create Firewall Rules (P2P + Dashboard + Metrics)
echo "Configuring Firewalls..."
$GCLOUD compute firewall-rules create conscia-p2p \
    --description="Relay P2P traffic" \
    --allow udp:30001 \
    --target-tags=relay-node --quiet

$GCLOUD compute firewall-rules create conscia-dashboard \
    --description="Relay Management Dashboard" \
    --allow tcp:3000 \
    --target-tags=relay-node --quiet

$GCLOUD compute firewall-rules create conscia-metrics \
    --description="Relay Prometheus metrics" \
    --allow tcp:9090 \
    --target-tags=relay-node --quiet

# 4. Launch E2-Micro Instance
echo "Provisioning Relay Instance (e2-micro)..."
$GCLOUD compute instances create relay-node-01 \
    --zone=us-central1-a \
    --machine-type=e2-micro \
    --network-interface=network-tier=PREMIUM,subnet=default \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=$($GCLOUD config get-value account) \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --tags=relay-node \
    --create-disk=auto-delete=yes,boot=yes,device-name=relay-node-01,image=projects/debian-cloud/global/images/debian-12-bookworm-v20240312,mode=rw,size=10,type=projects/$PROJECT_ID/zones/us-central1-a/diskTypes/pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any --quiet

echo "Relay Node Provisioned. Waiting for IP address..."
EXTERNAL_IP=$($GCLOUD compute instances describe relay-node-01 --zone=us-central1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "SUCCESS: Relay Node is alive at: http://$EXTERNAL_IP:3000"
