# wg-hoenn

Shared configuration for the Hoenn WireGuard network. The clients live in Hoenn;
Sunnyshore, the hub and DNS server, lives in Sinnoh.

`network.nix` owns the public peer inventory, addresses, subnet, hub endpoint,
and DNS domain. This repository contains no private keys. Consumers supply
runtime key paths and retain their SOPS configuration and firewall policy.

## Exports

- `lib.network`: public network inventory, including `nodes.<name>.address` and `publicKey`.
- `nixosModules.default` and `nixosModules.client`: client interface and split DNS.
- `nixosModules.hub`: hub interface, client peers, and IPv4 forwarding.
- `nixosModules.lan`: direct LAN routing support alongside Tailscale.
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
{
  imports = [inputs.wg-hoenn.nixosModules.client];
  wg-hoenn.privateKeyFile = config.sops.secrets.wireguard-hoenn-private.path;
}
```

The node name defaults to `networking.hostName`. Set `wg-hoenn.nodeName` explicitly
when the host name differs from its inventory name. Sunnyshore imports
`nixosModules.hub` instead.

Consumers must configure firewall access and secret provisioning. The hub needs
its WireGuard UDP listen port allowed; clients need the access appropriate for
their workloads. The LAN module configures policy routing but does not open
firewall ports or choose direct peer endpoints.

The Darwin module does not include Hoenn's temporary nix-darwin launchd patch.
Consumers that need that patch retain it locally.

## Change a peer

Edit `network.nix`, validate, and publish the change. Update the `wg-hoenn` input
in both Hoenn and Sinnoh, then validate and deploy through their normal GitOps
process. Each consumer pins its own revision, so publishing this flake alone
does not update the running network. Stage key rotations and removals across
both deployments.

Generate DNS records and direct LAN peer references from `lib.network.nodes`
rather than copying addresses or public keys.

## Development

Enter `nix develop`, or enable direnv with `direnv allow`. Run:

```sh
just fmt
just check
just update nixpkgs
```

Checks validate unique addresses and public keys, client/hub peer agreement,
key-path wiring, unknown node rejection, and Darwin configuration. GitHub Actions
runs checks on Linux and macOS. Renovate updates flake inputs and pinned Actions;
routine updates can merge after required checks pass.
