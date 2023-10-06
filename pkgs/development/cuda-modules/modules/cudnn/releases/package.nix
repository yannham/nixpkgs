{lib, ...}: let
  inherit (lib) options types;

  CudaVersionConstraint = options.mkOption {
    description = "A constraint on the supported CUDA versions";
    type = types.strMatching "^([[:digit:]]+)\\.([[:digit:]]+)$";
  };

  example = {
    version = "8.4.1.50";
    minCudaVersion = "11.0";
    maxCudaVersion = "11.7";
    url = "https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-sbsa/cudnn-linux-sbsa-8.4.1.50_cuda11.6-archive.tar.xz";
    hash = "sha256-CxufrFt4l04v2qp0hD2xj2Ns6PPZmdYv8qYVuZePw2A=";
  };
in
  options.mkOption {
    description = "A CUDNN tarball packaged for a specific platform";
    inherit example;
    type = types.submodule {
      options = {
        version = options.mkOption {
          description = "The version of CUDNN";
          type = types.strMatching "^([[:digit:]]+)\\.([[:digit:]]+)\\.([[:digit:]]+)\\.([[:digit:]]+)$";
        };
        minCudaVersion = CudaVersionConstraint;
        maxCudaVersion = CudaVersionConstraint;
        url = options.mkOption {
          description = "The URL to download the tarball from";
          type = types.str;
        };
        hash = options.mkOption {
          description = "The hash of the tarball";
          type = types.str;
        };
      };
    };
  }
