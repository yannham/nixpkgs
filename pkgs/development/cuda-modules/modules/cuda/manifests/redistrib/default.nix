{lib, ...}: {
  options.cuda.manifests.redistrib = import ./manifest.nix {inherit lib;};
}
