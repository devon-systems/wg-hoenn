{config, ...}: let
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
  environment.etc."resolver/hoenn".text = "nameserver ${hub.address}";
  networking.wg-quick.interfaces.hoenn = {
    address = ["${node.address}/${toString network.prefixLength}"];
    privateKeyFile = privateKey;
    preUp = ''
      while [ ! -r ${privateKey} ]; do
        /bin/sleep 1
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
