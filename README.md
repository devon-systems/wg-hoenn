# wg-hoenn

Shared configuration for the Hoenn WireGuard network. The clients live in Hoenn;
Sunnyshore, the hub and DNS server, lives in Sinnoh.

`network.nix` owns the public peer inventory, addresses, subnet, hub endpoint,
and DNS domain. This repository contains no private keys. Consumers supply
runtime key paths and keep their SOPS configuration and firewall policy.

## Exports

- `lib.network`: public network inventory, including `nodes.<name>.address` and `publicKey`.
- `nixosModules.default` and `nixosModules.client`: client interface and split DNS.
- `nixosModules.hub`: hub interface, client peers, and IPv4 forwarding.
- `nixosModules.lan`: direct LAN routing support alongside Tailscale. Import alongside the client module.
- `darwinModules.default`: client interface and the macOS domain resolver.

The modules use the consumer's package set. The flake's nixpkgs and nix-darwin
inputs provide development tools and evaluation tests.

## Use a module

Add an input:

```nix
inputs.wg-hoenn.url = "github:devon-systems/wg-hoenn";
```

Import the client module into a NixOS host:

```nix
{config, inputs, ...}: {
  imports = [inputs.wg-hoenn.nixosModules.client];
  wg-hoenn.privateKeyFile = config.sops.secrets.wireguard-hoenn-private.path;
}
```

The example assumes `inputs` is passed through `specialArgs` and the named SOPS secret is provisioned.

The node name defaults to `networking.hostName`. Set `wg-hoenn.nodeName` explicitly
when the host name differs from its inventory name. Sunnyshore imports
`nixosModules.hub` instead.

Consumers own firewall rules and secret provisioning. The hub and LAN hosts must
allow UDP `networking.wireguard.interfaces.hoenn.listenPort`. The LAN module adds
policy routing. It does not open ports or set direct peer endpoints.

The Darwin module does not backport nix-darwin#1738. Hoenn keeps that backport in
`nix/modules/wireguard-hoenn/default.nix`. The module waits up to 60 seconds for
the private-key file, then exits with an error that names the file.

## Change a peer

Edit `network.nix`, run `nix fmt` and `nix flake check`, then commit and push to
`master`. In each consumer, run `nix flake update wg-hoenn`, run its required
checks, and commit and push the lock file. Comin reconciles managed NixOS hosts
from each consumer's `master`. Darwin deployment remains the consumer's responsibility.

Hoenn and Sinnoh schedule Renovate lock maintenance every night before 4am,
America/New_York time. Passing updates auto-merge independently. Publishing a
change makes it eligible for both consumers' next update. Neither deployment
order nor completion time is guaranteed.

For a new peer, provision its private key and add the inventory entry before
configuring the client. Update Sinnoh first, then enable the client in Hoenn.
For removal, remove the client's module imports and direct peer references first,
then remove its inventory entry and update both consumers.

For key rotation, arrange a maintenance window and access outside the tunnel
before publishing the new public key. Prepare the new private key in the client's
secret configuration. Update Sinnoh's lock and let the hub reconcile, then update
the client's lock together with its secret. The tunnel is unavailable until both
deployments use matching keys. Nightly automerge can begin this transition early,
so publish only when ready for that interruption. Verify the handshake and DNS
after both deployments. Use a separate temporary peer and address if uninterrupted
access is required.

Generate DNS records and direct LAN peer references from `lib.network.nodes`
rather than copying addresses or public keys.

## Development

Enter `nix develop`, or enable direnv with `direnv allow`. Run:

```sh
just fmt
just check
just update nixpkgs
```

Checks validate unique addresses and public keys, subnet membership, endpoint
ports, client and hub peer agreement, module role assertions, and LAN routing
hooks and overrides. They check that modules use the supplied private-key file
and that Darwin configures the domain resolver.

GitHub Actions runs checks on Linux and macOS. Renovate auto-merges minor, patch,
digest, pin, and nightly lock updates after `check (ubuntu-latest)` and
`check (macos-latest)` pass. Major updates wait for review.
