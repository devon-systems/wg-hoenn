_: {
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      packages = [pkgs.git pkgs.gh pkgs.just pkgs.nixd];
    };
  };
}
