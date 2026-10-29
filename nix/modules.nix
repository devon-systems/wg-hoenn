{lib, ...}: {
  options.flake.darwinModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
    default = {};
  };
  config.flake = {
    lib.network = import ../network.nix;
    nixosModules = {
      default = import ../modules/client.nix;
      client = import ../modules/client.nix;
      hub = import ../modules/hub.nix;
      lan = import ../modules/lan.nix;
    };
    darwinModules.default = import ../modules/darwin.nix;
  };
}
