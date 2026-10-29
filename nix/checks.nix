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
  evaluateDarwin = name: privateKeyFile:
    (inputs.nix-darwin.lib.darwinSystem {
      modules = [
        self.darwinModules.default
        {
          nixpkgs.hostPlatform = "aarch64-darwin";
          networking.hostName = name;
          wg-hoenn.privateKeyFile = privateKeyFile;
          system.stateVersion = 6;
        }
      ];
    }).config;
  darwin = evaluateDarwin "verdanturf" "/run/keys/hoenn";
  lan =
    (evaluate "mauville" {
      imports = [self.nixosModules.client self.nixosModules.lan];
    }).networking.wireguard.interfaces.hoenn;
  overriddenLan =
    (evaluate "petalburg" {
      imports = [self.nixosModules.client self.nixosModules.lan];
      networking.wireguard.interfaces.hoenn = {
        listenPort = 51822;
        fwMark = lib.mkForce "12345";
      };
    }).networking.wireguard.interfaces.hoenn;
  hasFailure = message: cfg: lib.any (entry: !entry.assertion && entry.message == message) cfg.assertions;
  validRole = cfg: lib.all (entry: entry.assertion || !lib.hasPrefix "The Hoenn hub" entry.message) cfg.assertions;
  nodeType =
    (inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [self.nixosModules.client];
    }).options.wg-hoenn.nodeName.type;
  check = message: condition: lib.assertMsg condition "wg-hoenn: ${message}";
in {
  perSystem = {pkgs, ...}: {
    checks.darwin-key-wait = let
      keyPath = "/tmp/wg-hoenn missing 'key'; $(false)";
      script = (evaluateDarwin "verdanturf" keyPath).networking.wg-quick.interfaces.hoenn.preUp;
      fastScript = lib.replaceStrings ["/bin/sleep 1"] [":"] script;
      readableScript = (evaluateDarwin "verdanturf" "/dev/null").networking.wg-quick.interfaces.hoenn.preUp;
    in
      pkgs.runCommand "wg-hoenn-darwin-key-wait" {} ''
        bash -n ${pkgs.writeText "key-wait.sh" script}
        bash ${pkgs.writeText "readable-key.sh" readableScript}
        if bash ${pkgs.writeText "missing-key.sh" fastScript} 2>error; then
          echo "Missing key did not fail" >&2
          exit 1
        fi
        grep -F -- ${lib.escapeShellArg "WireGuard private key is not readable: ${keyPath}"} error
        touch "$out"
      '';
    checks.network = assert check "duplicate addresses" (lib.length addresses == lib.length (lib.unique addresses));
    assert check "duplicate public keys" (lib.length keys == lib.length (lib.unique keys));
    assert check "nodeName enum" (!nodeType.check "unknown-peer" && lib.all nodeType.check names);
    assert check "client accepts hub role" (hasFailure "The Hoenn hub must import wg-hoenn.nixosModules.hub." (evaluate network.hub self.nixosModules.client));
    assert check "hub accepts client role" (hasFailure "The Hoenn hub module is reserved for ${network.hub}." (evaluate "mauville" {
      imports = [self.nixosModules.hub];
      wg-hoenn.nodeName = "mauville";
    }));
    assert check "Darwin accepts hub role" (hasFailure "The Hoenn hub requires NixOS." (evaluateDarwin network.hub "/run/keys/hoenn"));
    assert check "valid roles rejected" (validRole darwin && validRole (evaluate network.hub self.nixosModules.hub) && lib.all (name: validRole (evaluate name self.nixosModules.client)) clientNames);
    assert check "LAN defaults" (lan.listenPort == network.listenPort && lan.fwMark == "51821");
    assert check "LAN DNS setup" (lib.hasInfix "resolvectl dns hoenn" lan.postSetup);
    assert check "LAN setup" (lib.hasInfix "rule add priority 5201 fwmark 51821 lookup main suppress_prefixlength 0" lan.postSetup);
    assert check "LAN cleanup" (lib.hasInfix "rule del priority 5201 fwmark 51821 lookup main suppress_prefixlength 0" lan.postShutdown);
    assert check "LAN overrides" (overriddenLan.listenPort == 51822 && lib.hasInfix "fwmark 12345" overriddenLan.postSetup && lib.hasInfix "fwmark 12345" overriddenLan.postShutdown);
    assert check "hub address" (hub.ips == ["${network.nodes.${network.hub}.address}/${toString network.prefixLength}"]);
    assert check "hub listen port" (hub.listenPort == network.listenPort);
    assert check "hub private key path" (hub.privateKeyFile == "/run/keys/hoenn");
    assert check "hub peer count" (lib.length hub.peers == lib.length clientNames);
    assert lib.all (client:
      check "${client.name}: interface or hub peer mismatch" (client.interface.ips
        == ["${network.nodes.${client.name}.address}/${toString network.prefixLength}"]
        && client.interface.privateKeyFile == "/run/keys/hoenn"
        && lib.length client.interface.peers == 1
        && (builtins.head client.interface.peers).allowedIPs == [network.subnet]
        && (builtins.head client.interface.peers).publicKey == network.nodes.${network.hub}.publicKey
        && (builtins.head client.interface.peers).endpoint == network.endpoint
        && lib.any (peer:
          peer.publicKey
          == network.nodes.${client.name}.publicKey
          && peer.allowedIPs == ["${network.nodes.${client.name}.address}/32"])
        hub.peers))
    clients;
    assert check "Darwin address" (darwin.networking.wg-quick.interfaces.hoenn.address == ["${network.nodes.verdanturf.address}/${toString network.prefixLength}"]);
    assert check "Darwin private key path" (darwin.networking.wg-quick.interfaces.hoenn.privateKeyFile == "/run/keys/hoenn");
    assert check "Darwin hub key" ((builtins.head darwin.networking.wg-quick.interfaces.hoenn.peers).publicKey == network.nodes.${network.hub}.publicKey);
    assert check "Darwin resolver" (darwin.environment.etc."resolver/${network.domain}".text == "nameserver ${network.nodes.${network.hub}.address}");
      pkgs.runCommand "wg-hoenn-network-check" {
        nativeBuildInputs = [pkgs.python3];
        inventory = builtins.toJSON network;
        passAsFile = ["inventory"];
      } ''
        python ${../tests/network.py} "$inventoryPath"
        touch "$out"
      '';
  };
}
