{lib, ...}: let
  inherit (lib) options types;
in
  # https://github.com/ConnorBaker/cuda-redist-find-features/blob/c841980e146f8664bbcd0ba1399e486b7910617b/cuda_redist_find_features/types/_lib_so_name.py
  options.mkOption {
    description = "The name of a shared object file.";
    example = "libcublas.so.11";
    type = types.strMatching ".*\\.so(\\.[[:digit:]]+)*$";
  }
