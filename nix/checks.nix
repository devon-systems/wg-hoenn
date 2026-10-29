{
  inputs,
  self,
  lib,
  ...
}: let
  network = import ../network.nix;
  names = builtins.attrNames network.nodes;
  clientNames = lib.remove network.hub names;
  addresses = map (name: network.nodes.${name}.address) names;
  keys = map (name: network.nodes.${name}.publicKey) names;
  evaluate = name: module:
    (inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        module
        {
          networking.hostName = name;
          wg-hoenn.privateKeyFile = "/run/keys/hoenn";
          system.stateVersion = "26.05";
        }
      ];
    }).config;
  hub = (evaluate network.hub self.nixosModules.hub).networking.wireguard.interfaces.hoenn;
  clients =
    map (name: {
      inherit name;
      interface = (evaluate name self.nixosModules.client).networking.wireguard.interfaces.hoenn;
    })
    clientNames;
  darwin =
    (inputs.nix-darwin.lib.darwinSystem {
      modules = [
        self.darwinModules.default
        {
          nixpkgs.hostPlatform = "aarch64-darwin";
          networking.hostName = "verdanturf";
          wg-hoenn.privateKeyFile = "/run/keys/hoenn";
          system.stateVersion = 6;
        }
      ];
    }).config;
  invalid = builtins.tryEval (evaluate "unknown-peer" self.nixosModules.client).wg-hoenn.nodeName;
in {
  perSystem = {pkgs, ...}: {
    checks.network = assert lib.length addresses == lib.length (lib.unique addresses);
    assert lib.length keys == lib.length (lib.unique keys);
    assert !invalid.success;
    assert hub.ips == ["${network.nodes.${network.hub}.address}/24"];
    assert hub.listenPort == network.listenPort;
    assert hub.privateKeyFile == "/run/keys/hoenn";
    assert lib.length hub.peers == lib.length clientNames;
    assert lib.all (client:
      client.interface.ips
      == ["${network.nodes.${client.name}.address}/24"]
      && client.interface.privateKeyFile == "/run/keys/hoenn"
      && lib.length client.interface.peers == 1
      && (builtins.head client.interface.peers).allowedIPs == [network.subnet]
      && (builtins.head client.interface.peers).publicKey == network.nodes.${network.hub}.publicKey
      && (builtins.head client.interface.peers).endpoint == network.endpoint
      && lib.any (peer:
        peer.publicKey
        == network.nodes.${client.name}.publicKey
        && peer.allowedIPs == ["${network.nodes.${client.name}.address}/32"])
      hub.peers)
    clients;
    assert darwin.networking.wg-quick.interfaces.hoenn.address == ["${network.nodes.verdanturf.address}/24"];
    assert darwin.networking.wg-quick.interfaces.hoenn.privateKeyFile == "/run/keys/hoenn";
    assert (builtins.head darwin.networking.wg-quick.interfaces.hoenn.peers).publicKey == network.nodes.${network.hub}.publicKey;
    assert darwin.environment.etc."resolver/hoenn".text == "nameserver ${network.nodes.${network.hub}.address}";
      pkgs.runCommand "wg-hoenn-network-check" {} ''
        touch "$out"
      '';
  };
}
