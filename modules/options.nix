{
  config,
  lib,
  ...
}: let
  network = import ../network.nix;
in {
  options.wg-hoenn = {
    nodeName = lib.mkOption {
      type = lib.types.enum (builtins.attrNames network.nodes);
      default = config.networking.hostName;
      description = "Name of this host in the Hoenn peer inventory.";
    };
    privateKeyFile = lib.mkOption {
      type = lib.types.str;
      description = "Runtime path to this host's WireGuard private key, provisioned by the caller.";
    };
  };
}
