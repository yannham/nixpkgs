{lib, ...}: {
  options.cuda.manifests.feature = import ./manifest.nix {inherit lib;};
}
