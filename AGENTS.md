# Work in wg-hoenn

This repository owns the public Hoenn WireGuard peer inventory and reusable NixOS and nix-darwin modules. Deployment repositories own secrets, firewall policy, and service deployment.

- Edit peer names, addresses, public keys, and the public hub endpoint in `network.nix`.
- Keep module exports stable. Runtime private-key paths come from `wg-hoenn.privateKeyFile`; never put private keys or encrypted credentials here.
- Keep host-specific LAN endpoints and Darwin compatibility patches in consumer repositories.
- Before committing, run `nix fmt` and `nix flake check`. CI checks Linux and macOS.
- After module changes, compare evaluated consumer configurations and build affected hosts. Do not deploy or force reconciliation to test.
- Use scoped Conventional Commits.
- Peer changes require updating the flake lock in both Hoenn and Sinnoh. Coordinate both sides before removing a peer or rotating a public key.
