{lib, ...}: let
  inherit (lib) options types;
  Package = import ./package.nix {inherit lib;};
  example = {
    # jetson
    linux-aarch64 = [
      {
        version = "8.9.0.131";
        minCudaVersion = "12.0";
        maxCudaVersion = "12.1";
        url = "https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-aarch64/cudnn-linux-aarch64-8.9.0.131_cuda12-archive.tar.xz";
        hash = "sha256-+rcPT7O5M/9QIgCh2VTSxvwgX/nJsdJx6kxB6YCmZZY=";
      }
    ];
    # powerpc
    linux-ppc64le = [];
    # server-grade arm
    linux-sbsa = [
      {
        version = "8.4.1.50";
        minCudaVersion = "11.0";
        maxCudaVersion = "11.7";
        url = "https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-sbsa/cudnn-linux-sbsa-8.4.1.50_cuda11.6-archive.tar.xz";
        hash = "sha256-CxufrFt4l04v2qp0hD2xj2Ns6PPZmdYv8qYVuZePw2A=";
      }
      {
        version = "8.5.0.96";
        minCudaVersion = "11.0";
        maxCudaVersion = "11.7";
        url = "https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-sbsa/cudnn-linux-sbsa-8.5.0.96_cuda11-archive.tar.xz";
        hash = "sha256-hngKu+zUY05zY/rR0ACuI7eQWl+Dg73b9zMsaTR5Hd4=";
      }
    ];
  };
in
  options.mkOption {
    description = "A collection of CUDNN packages targeting different platforms";
    inherit example;
    type = types.attrsOf Package.type;
  }
