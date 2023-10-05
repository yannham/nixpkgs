{lib, ...}: {
  options.feature_manifest = import ./manifest.nix {inherit lib;};
}
