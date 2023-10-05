{lib, ...}: let
  inherit (lib) options types;
in
  options.mkOption {
    description = "A CUDA architecture name.";
    example = "sm_90a";
    type = types.strMatching "^sm_[[:digit:]]+[a-z]?$";
  }
