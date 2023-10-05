{lib, ...}: {
  options.redistrib_manifest = import ./manifest.nix {inherit lib;};
}
