#!/usr/bin/env bash
set -euo pipefail

export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

if ! command -v iota >/dev/null 2>&1; then
  echo "ERROR: iota CLI not found. Try: source ~/.bashrc"
  exit 1
fi

echo "=========================================="
echo "IOTA Rebased one-shot deploy"
echo "=========================================="
iota --version

# ---------- Configure client to point at testnet ----------
CONFIG_DIR="${HOME}/.iota/iota_config"
mkdir -p "${CONFIG_DIR}"

if [ ! -f "${CONFIG_DIR}/client.yaml" ]; then
  echo ""
  echo "Configuring iota client for testnet..."
  # CLI 1.22+ prompts:
  #   1. "Select a default network..." -> "testnet"
  #   2. "Connection alias..."          -> "testnet"
  #   3. "Select key scheme..."         -> "0" (ed25519)
  iota client <<EOF || true
testnet
testnet
0
EOF
fi

# Make sure we have an address
if ! iota client active-address >/dev/null 2>&1; then
  iota client new-address ed25519
fi

ADDRESS=$(iota client active-address)
echo ""
echo "Using address: ${ADDRESS}"

# ---------- Faucet ----------
echo ""
echo "Requesting tokens from the testnet faucet..."
iota client faucet || echo "Faucet may have already funded this address; continuing."
echo "Waiting 30 seconds for tokens to land..."
sleep 30

echo ""
echo "Current gas balance:"
iota client gas

# ---------- Build + publish ----------
echo ""
echo "=========================================="
echo "Building Move package..."
echo "=========================================="
cd "$(dirname "$0")/move"
iota move build

echo ""
echo "=========================================="
echo "Publishing package to IOTA Rebased testnet..."
echo "=========================================="
PUBLISH_JSON=$(iota client publish --gas-budget 100000000 --json)
echo "${PUBLISH_JSON}" > /tmp/publish.json

# ---------- Parse IDs ----------
if command -v jq >/dev/null 2>&1; then
  PACKAGE_ID=$(echo "${PUBLISH_JSON}" | jq -r '.objectChanges[]? | select(.type == "published") | .packageId' | head -1)
  HUB_ID=$(echo "${PUBLISH_JSON}" | jq -r '.objectChanges[]? | select(.objectType? // "" | endswith("::sensor::SensorHub")) | .objectId' | head -1)
else
  PACKAGE_ID=$(echo "${PUBLISH_JSON}" | grep -oE '"packageId":\s*"0x[0-9a-fA-F]+"' | head -1 | sed -E 's/.*"(0x[^"]+)".*/\1/')
  HUB_ID=$(echo "${PUBLISH_JSON}" | grep -B1 -A1 'SensorHub' | grep -oE '"objectId":\s*"0x[0-9a-fA-F]+"' | head -1 | sed -E 's/.*"(0x[^"]+)".*/\1/')
fi

echo ""
echo "=========================================="
echo "  DEPLOYMENT SUCCESSFUL"
echo "=========================================="
echo ""
echo "PACKAGE_ID:    ${PACKAGE_ID:-NOT FOUND — see /tmp/publish.json}"
echo "SENSOR_HUB_ID: ${HUB_ID:-NOT FOUND — see /tmp/publish.json}"
echo "OWNER ADDRESS: ${ADDRESS}"
echo ""
echo "------------------------------------------"
echo "Copy into your local dApp's .env.local:"
echo "------------------------------------------"
echo ""
echo "VITE_PACKAGE_ID=${PACKAGE_ID}"
echo "VITE_SENSOR_HUB_ID=${HUB_ID}"
echo "VITE_TESTNET_RPC=https://api.testnet.iota.cafe"
echo ""
echo "=========================================="
echo "Verify on the explorer:"
echo "  https://explorer.iota.org/?network=testnet"
echo "=========================================="
