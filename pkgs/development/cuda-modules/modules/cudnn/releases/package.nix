{lib, ...}: let
  inherit (lib) options types;

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
        version = types.strMatching "^([[:digit:]]+)\\.([[:digit:]]+)\\.([[:digit:]]+)\\.([[:digit:]]+)$";
        minCudaVersion = types.strMatching "^([[:digit:]]+)\\.([[:digit:]]+)$";
        maxCudaVersion = types.strMatching "^([[:digit:]]+)\\.([[:digit:]]+)$";
        url = types.str;
        hash = types.str;
      };
    };
  }
