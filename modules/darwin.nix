{
  config,
  lib,
  ...
}: let
  network = import ../network.nix;
  node = network.nodes.${config.wg-hoenn.nodeName};
  hub = network.nodes.${network.hub};
  privateKey = config.wg-hoenn.privateKeyFile;
in {
  imports = [./options.nix];
  assertions = [
    {
      assertion = config.wg-hoenn.nodeName != network.hub;
      message = "The Hoenn hub requires NixOS.";
    }
  ];
  environment.etc."resolver/${network.domain}".text = "nameserver ${hub.address}";
  networking.wg-quick.interfaces.hoenn = {
    address = ["${node.address}/${toString network.prefixLength}"];
    privateKeyFile = privateKey;
    preUp = ''
      attempts=0
      while [ ! -r ${lib.escapeShellArg privateKey} ]; do
        if [ "$attempts" -ge 60 ]; then
          printf '%s\n' ${lib.escapeShellArg "WireGuard private key is not readable: ${privateKey}"} >&2
          exit 1
        fi
        /bin/sleep 1
        attempts=$((attempts + 1))
      done
    '';
    peers = [
      {
        allowedIPs = [network.subnet];
        inherit (network) endpoint;
        persistentKeepalive = 25;
        inherit (hub) publicKey;
      }
    ];
  };
}
