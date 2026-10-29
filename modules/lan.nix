{
  config,
  lib,
  pkgs,
  ...
}: let
  network = import ../network.nix;
  interface = config.networking.wireguard.interfaces.hoenn;
in {
  networking.wireguard.interfaces.hoenn = {
    listenPort = lib.mkDefault network.listenPort;
    fwMark = "51821";

    # Keep WireGuard UDP on connected networks ahead of Tailscale subnet routes.
    postSetup = ''
      ${pkgs.iproute2}/bin/ip -4 rule add priority 5201 fwmark ${interface.fwMark} lookup main suppress_prefixlength 0
    '';
    postShutdown = ''
      ${pkgs.iproute2}/bin/ip -4 rule del priority 5201 fwmark ${interface.fwMark} lookup main suppress_prefixlength 0
    '';
  };
}
