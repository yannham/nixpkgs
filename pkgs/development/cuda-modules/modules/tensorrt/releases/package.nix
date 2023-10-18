{lib, ...}: let
  inherit (lib) options types;

  VersionConstraint = options.mkOption {
    description = "A constraint on the supported versions";
    type = types.strMatching "^([[:digit:]]+)\\.([[:digit:]]+)$";
  };

  OptionalVersionConstraint = options.mkOption {
    description = "A constraint on the supported versions";
    type = types.nullOr VersionConstraint.type;
  };

  example = {
    version = "8.0.3.4";
    minCudaVersion = "10.2";
    maxCudaVersion = "10.2";
    cudnnVersion = "8.2";
    filename = "TensorRT-8.0.3.4.Linux.x86_64-gnu.cuda-10.2.cudnn8.2.tar.gz";
    hash = "sha256-LxcXgwe1OCRfwDsEsNLIkeNsOcx3KuF5Sj+g2dY6WD0=";
  };
in
  options.mkOption {
    description = "A TensorRT tarball packaged for a specific platform";
    inherit example;
    type = types.submodule {
      options = {
        version = options.mkOption {
          description = "The version of TensorRT";
          type = types.strMatching "^([[:digit:]]+)\\.([[:digit:]]+)\\.([[:digit:]]+)\\.([[:digit:]]+)$";
        };
        minCudaVersion = VersionConstraint;
        maxCudaVersion = VersionConstraint;
        cudnnVersion = OptionalVersionConstraint;
        filename = options.mkOption {
          description = "The tarball name";
          type = types.str;
        };
        hash = options.mkOption {
          description = "The hash of the tarball";
          type = types.str;
        };
      };
    };
  }
