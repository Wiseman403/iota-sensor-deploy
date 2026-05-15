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

@Wiseman403 ➜ ~ $ iota client addresses
╭─────────────────────┬────────────────────────────────────────────────────────────────────┬─────────┬────────╮
│ alias               │ address                                                            │ source  │ active │
├─────────────────────┼────────────────────────────────────────────────────────────────────┼─────────┼────────┤
│ mystifying-idocrase │ 0xabcf39eb4b4d7a5faf37ad91c0402e821ea770b85993d963de9c64287848e941 │ keypair │ *      │
╰─────────────────────┴────────────────────────────────────────────────────────────────────┴─────────┴────────╯


@Wiseman403 ➜ ~ $ iota keytool export mystifying-idocrase
╭────────────────────┬────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ exportedPrivateKey │  iotaprivkey1qzf3lscvv20w5509kw52f7xa9sl335dw6lvrzu43wp36keaydjz2ua3df2l                           │
│ key                │ ╭─────────────────────────┬──────────────────────────────────────────────────────────────────────╮ │
│                    │ │ alias                   │  mystifying-idocrase                                                 │ │
│                    │ │ iotaAddress             │  0xabcf39eb4b4d7a5faf37ad91c0402e821ea770b85993d963de9c64287848e941  │ │
│                    │ │ source                  │  keypair                                                             │ │
│                    │ │ publicBase64Key         │  3kEkufVpVqWIxpA0SYRbp5GTH9pgXI2k14EYW/tB4gU=                        │ │
│                    │ │ publicBase64KeyWithFlag │  AN5BJLn1aValiMaQNEmEW6eRkx/aYFyNpNeBGFv7QeIF                        │ │
│                    │ │ keyScheme               │  ed25519                                                             │ │
│                    │ │ flag                    │  0                                                                   │ │
│                    │ │ peerId                  │  de4124b9f56956a588c6903449845ba791931fda605c8da4d781185bfb41e205    │ │
│                    │ ╰─────────────────────────┴──────────────────────────────────────────────────────────────────────╯ │
╰────────────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────╯

# cup business save angle able rookie goddess surround rabbit powder eternal upgrade
