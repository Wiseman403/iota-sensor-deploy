#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo "Installing IOTA CLI for IOTA Rebased"
echo "=========================================="

# We try the binary download first (fast, ~30s).
# If that fails for any reason, we fall back to building from source via cargo
# (slow, ~10–15 minutes but very reliable).

INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "${INSTALL_DIR}"

# Make sure ~/.local/bin is on PATH for future shells.
if ! grep -q '.local/bin' "${HOME}/.bashrc" 2>/dev/null; then
  echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> "${HOME}/.bashrc"
fi
export PATH="${HOME}/.local/bin:${PATH}"

install_via_cargo() {
  echo ""
  echo "Falling back to cargo install (this takes 10-15 minutes)..."
  echo "Grab a coffee. You will see lots of compiler output. That is normal."
  cargo install --locked \
    --git https://github.com/iotaledger/iota.git \
    --branch testnet \
    iota
}

# Try binary first.
echo ""
echo "Attempting binary install from GitHub releases..."
TMP_DIR=$(mktemp -d)
cd "${TMP_DIR}"

# Get the latest testnet release tag from the GitHub API.
LATEST_TAG=$(curl -s https://api.github.com/repos/iotaledger/iota/releases \
  | grep -m1 '"tag_name":' \
  | sed -E 's/.*"([^"]+)".*/\1/' || true)

if [ -z "${LATEST_TAG}" ]; then
  echo "Could not determine latest release tag."
  install_via_cargo
else
  echo "Latest release tag: ${LATEST_TAG}"

  # Asset naming has varied between releases. Try the most common patterns
  # in order. The first one that downloads wins.
  CANDIDATES=(
    "iota-${LATEST_TAG}-linux-x86_64.tgz"
    "iota-${LATEST_TAG}-ubuntu-x86_64.tgz"
    "iota-${LATEST_TAG}-linux-amd64.tgz"
  )

  DOWNLOADED=""
  for ASSET in "${CANDIDATES[@]}"; do
    URL="https://github.com/iotaledger/iota/releases/download/${LATEST_TAG}/${ASSET}"
    echo "Trying: ${URL}"
    if curl -L -f -o iota.tgz "${URL}" 2>/dev/null; then
      DOWNLOADED="yes"
      break
    fi
  done

  if [ -n "${DOWNLOADED}" ]; then
    tar -xzf iota.tgz
    # Find the iota binary in the extracted tree and copy it.
    IOTA_BIN=$(find . -type f -name 'iota' -executable | head -1)
    if [ -n "${IOTA_BIN}" ]; then
      cp "${IOTA_BIN}" "${INSTALL_DIR}/iota"
      chmod +x "${INSTALL_DIR}/iota"
      echo "Binary installed."
    else
      echo "Could not find iota binary in tarball. Falling back to cargo."
      install_via_cargo
    fi
  else
    install_via_cargo
  fi
fi

cd "${HOME}"
rm -rf "${TMP_DIR}"

# Verify installation
echo ""
echo "=========================================="
if command -v iota >/dev/null 2>&1; then
  iota --version
  echo "IOTA CLI ready."
else
  echo "IOTA CLI install FAILED. Check the output above."
  exit 1
fi
echo "=========================================="
