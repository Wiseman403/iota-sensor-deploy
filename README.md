# iota-sensor-deploy
# IOTA Sensor — One-Time Move Deploy

This repo exists for one purpose: to deploy the `sensor_package` Move contract to IOTA Rebased testnet from a GitHub Codespace, so the developer's local machine never needs the IOTA CLI.

## Quick start

1. Click **Code → Codespaces → Create codespace on main** at the top of this repo.
2. Wait ~3 minutes while the Codespace installs Rust and the IOTA CLI.
3. When the terminal is ready, run:

   ```bash
   chmod +x deploy.sh .devcontainer/install-iota.sh
   ./deploy.sh
   ```

4. At the end, the script prints `PACKAGE_ID` and `SENSOR_HUB_ID`. Copy them into your local dApp's `.env.local`.
5. Stop or delete the Codespace. You are done.

## Files

- `move/sources/sensor.move` — the smart contract (single Move module: `SensorHub` + `SensorData`).
- `move/Move.toml` — package configuration.
- `.devcontainer/` — Codespace setup.
- `deploy.sh` — one-shot deployment script.

## Notes

- The script uses the testnet faucet at `https://api.testnet.iota.cafe`. Tokens take up to one minute to land.
- If the binary install fails, the setup falls back to `cargo install`, which takes ~10 minutes but is more reliable.
- The published package's owner is the address generated inside the Codespace. Save the recovery phrase if you want to reuse the same address from your local machine — but you will not need it for the dApp, which uses its own browser-side keypair.
