{lib, ...}: {
  options.cudnn.releases = import ./releases.nix {inherit lib;};
}
