{
  config,
  lib,
  ...
}: let
  network = import ../network.nix;
  hub = network.nodes.${network.hub};
  clients = lib.removeAttrs network.nodes [network.hub];
in {
  imports = [./options.nix];
  wg-hoenn.nodeName = lib.mkDefault network.hub;
  assertions = [
    {
      assertion = config.wg-hoenn.nodeName == network.hub;
      message = "The Hoenn hub module is reserved for ${network.hub}.";
    }
  ];
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.wireguard.interfaces.hoenn = {
    ips = ["${hub.address}/${toString network.prefixLength}"];
    inherit (network) listenPort;
    privateKeyFile = config.wg-hoenn.privateKeyFile;
    peers =
      lib.mapAttrsToList (_: node: {
        allowedIPs = ["${node.address}/32"];
        inherit (node) publicKey;
      })
      clients;
  };
}
