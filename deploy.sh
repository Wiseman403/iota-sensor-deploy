#!/usr/bin/env bash
set -euo pipefail

# Make sure we can find the iota binary even in a fresh shell.
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

if ! command -v iota >/dev/null 2>&1; then
  echo "ERROR: iota CLI not found on PATH."
  echo "If the Codespace just finished setting up, try:  source ~/.bashrc"
  echo "Or open a new terminal and try again."
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
  # On first run, `iota client` is interactive. We feed it the answers it expects:
  #   - "y" to accept testnet
  #   - empty line to use default RPC URL
  #   - "testnet" alias
  #   - "0" for ed25519 key scheme
  iota client <<EOF || true
y

testnet
0
EOF
fi

# Make sure the testnet env exists; some CLI versions add it differently.
iota client envs >/dev/null 2>&1 || true
if ! iota client envs 2>/dev/null | grep -q testnet; then
  iota client new-env --alias testnet --rpc https://api.testnet.iota.cafe || true
fi
iota client switch --env testnet >/dev/null 2>&1 || true

# Make sure we have at least one address.
if ! iota client active-address >/dev/null 2>&1; then
  iota client new-address ed25519
fi

ADDRESS=$(iota client active-address)
echo ""
echo "Using address: ${ADDRESS}"

# ---------- Get test tokens ----------
echo ""
echo "Requesting tokens from the testnet faucet..."
iota client faucet || echo "Faucet may have already funded this address; continuing."
echo "Waiting 30 seconds for tokens to land..."
sleep 30

echo ""
echo "Current gas balance:"
iota client gas

# ---------- Build and test the Move package ----------
echo ""
echo "=========================================="
echo "Building Move package..."
echo "=========================================="
cd "$(dirname "$0")/move"
iota move build

# ---------- Publish ----------
echo ""
echo "=========================================="
echo "Publishing package to IOTA Rebased testnet..."
echo "=========================================="
PUBLISH_JSON=$(iota client publish --gas-budget 100000000 --json)
echo "${PUBLISH_JSON}" > /tmp/publish.json

# ---------- Parse out the IDs ----------
# Try jq first; fall back to a simple grep if jq is not available.
if command -v jq >/dev/null 2>&1; then
  PACKAGE_ID=$(echo "${PUBLISH_JSON}" | jq -r '.objectChanges[]? | select(.type == "published") | .packageId' | head -1)
  HUB_ID=$(echo "${PUBLISH_JSON}" | jq -r '.objectChanges[]? | select(.objectType? // empty | endswith("::sensor::SensorHub")) | .objectId' | head -1)
else
  echo "(jq not available; using grep fallback)"
  PACKAGE_ID=$(echo "${PUBLISH_JSON}" | grep -oE '"packageId":\s*"0x[0-9a-fA-F]+"' | head -1 | sed -E 's/.*"(0x[^"]+)".*/\1/')
  HUB_ID=$(echo "${PUBLISH_JSON}" | grep -B1 -A1 'SensorHub' | grep -oE '"objectId":\s*"0x[0-9a-fA-F]+"' | head -1 | sed -E 's/.*"(0x[^"]+)".*/\1/')
fi

# ---------- Print the results ----------
echo ""
echo "=========================================="
echo "  DEPLOYMENT SUCCESSFUL"
echo "=========================================="
echo ""
echo "PACKAGE_ID:    ${PACKAGE_ID:-NOT FOUND — check /tmp/publish.json}"
echo "SENSOR_HUB_ID: ${HUB_ID:-NOT FOUND — check /tmp/publish.json}"
echo "OWNER ADDRESS: ${ADDRESS}"
echo ""
echo "------------------------------------------"
echo "Copy these three lines into your local"
echo "Windows dApp's .env.local file:"
echo "------------------------------------------"
echo ""
echo "VITE_PACKAGE_ID=${PACKAGE_ID}"
echo "VITE_SENSOR_HUB_ID=${HUB_ID}"
echo "VITE_TESTNET_RPC=https://api.testnet.iota.cafe"
echo ""
echo "=========================================="
echo "Verify on the explorer:"
echo "  https://explorer.iota.org/?network=testnet"
echo "Search for the PACKAGE_ID or your address."
echo "=========================================="
