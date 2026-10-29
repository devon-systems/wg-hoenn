{
  config,
  pkgs,
  ...
}: let
  network = import ../network.nix;
  node = network.nodes.${config.wg-hoenn.nodeName};
  hub = network.nodes.${network.hub};
in {
  imports = [./options.nix];
  assertions = [
    {
      assertion = config.wg-hoenn.nodeName != network.hub;
      message = "The Hoenn hub must import wg-hoenn.nixosModules.hub.";
    }
  ];
  networking.wireguard.interfaces.hoenn = {
    ips = ["${node.address}/${toString network.prefixLength}"];
    privateKeyFile = config.wg-hoenn.privateKeyFile;
    postSetup = ''
      ${pkgs.systemd}/bin/resolvectl dns hoenn ${hub.address}
      ${pkgs.systemd}/bin/resolvectl domain hoenn ~${network.domain}
      ${pkgs.systemd}/bin/resolvectl default-route hoenn false
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
  services.resolved.enable = true;
  systemd.services.wireguard-hoenn.after = ["systemd-resolved.service"];
}
