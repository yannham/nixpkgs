{lib, ...}: {
  options.tensorrt.releases = import ./releases.nix {inherit lib;};
}
