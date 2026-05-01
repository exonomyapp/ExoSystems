#!/bin/bash
# Conscia GCP Bootstrap (Autonomous Launch)

# 1. Authenticate
# --- PEER SDK STRATEGY ---
# We keep the 1GB Google Cloud SDK outside the monorepo root to maintain
# workspace cleanliness. This dynamic path resolves to the peer directory.
GCLOUD="$(cd "$(dirname "$0")/../../google-cloud-sdk/bin" && pwd)/gcloud"
$GCLOUD auth activate-service-account --key-file="$(dirname "$0")/conscia-deploy-key.json"
$GCLOUD config set project gen-lang-client-0135693111 --quiet

# 2. Configure Project
PROJECT_ID=$($GCLOUD config get-value project)
echo "Launching Conscia in project: $PROJECT_ID"

# 3. Create Firewall Rules (P2P + Dashboard + Metrics)
echo "Configuring Sovereign Firewalls..."
$GCLOUD compute firewall-rules create conscia-p2p \
    --description="Conscia P2P traffic" \
    --allow udp:30001 \
    --target-tags=conscia-node --quiet

$GCLOUD compute firewall-rules create conscia-dashboard \
    --description="Conscia Management Dashboard" \
    --allow tcp:3000 \
    --target-tags=conscia-node --quiet

$GCLOUD compute firewall-rules create conscia-metrics \
    --description="Conscia Prometheus metrics" \
    --allow tcp:9090 \
    --target-tags=conscia-node --quiet

# 4. Launch E2-Micro Instance
echo "Provisioning Conscia Instance (e2-micro)..."
$GCLOUD compute instances create conscia-node-01 \
    --zone=us-central1-a \
    --machine-type=e2-micro \
    --network-interface=network-tier=PREMIUM,subnet=default \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=$($GCLOUD config get-value account) \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --tags=conscia-node \
    --create-disk=auto-delete=yes,boot=yes,device-name=conscia-node-01,image=projects/debian-cloud/global/images/debian-12-bookworm-v20240312,mode=rw,size=10,type=projects/$PROJECT_ID/zones/us-central1-a/diskTypes/pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any --quiet

echo "Conscia Node Provisioned. Waiting for IP address..."
EXTERNAL_IP=$($GCLOUD compute instances describe conscia-node-01 --zone=us-central1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "SUCCESS: Conscia Node is alive at: http://$EXTERNAL_IP:3000"
