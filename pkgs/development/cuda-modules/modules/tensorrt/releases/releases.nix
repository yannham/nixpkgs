{lib, ...}: let
  inherit (lib) options types;
  Package = import ./package.nix {inherit lib;};
  example = {
    # server-grade arm
    linux-sbsa = [
      {
        version = "8.5.3.1";
        minCudaVersion = "11.8";
        maxCudaVersion = "11.8";
        cudnnVersion = "8.6";
        filename = "TensorRT-8.5.3.1.Ubuntu-20.04.aarch64-gnu.cuda-11.8.cudnn8.6.tar.gz";
        hash = "sha256-GW//mX0brvN/waHo9Wd07xerOEz3X/H/HAW2ZehYtTA=";
      }
      {
        version = "8.6.1.6";
        minCudaVersion = "12.0";
        maxCudaVersion = "12.0";
        cudnnVersion = null;
        filename = "TensorRT-8.6.1.6.Ubuntu-20.04.aarch64-gnu.cuda-12.0.tar.gz";
        hash = "sha256-Lc4+v/yBr17VlecCSFMLUDlXMTYV68MGExwnUjGme5E=";
      }
    ];
    # x86_64
    linux-x86_64 = [
      {
        version = "8.5.3.1";
        minCudaVersion = "10.2";
        maxCudaVersion = "10.2";
        cudnnVersion = "8.6";
        filename = "TensorRT-8.5.3.1.Linux.x86_64-gnu.cuda-10.2.cudnn8.6.tar.gz";
        hash = "sha256-WCt6yfOmFbrjqdYCj6AE2+s2uFpISwk6urP+2I0BnGQ=";
      }
      {
        version = "8.5.3.1";
        minCudaVersion = "11.0";
        maxCudaVersion = "11.8";
        cudnnVersion = "8.6";
        filename = "TensorRT-8.5.3.1.Linux.x86_64-gnu.cuda-11.8.cudnn8.6.tar.gz";
        hash = "sha256-BNeuOYvPTUAfGxI0DVsNrX6Z/FAB28+SE0ptuGu7YDY=";
      }
      {
        version = "8.6.1";
        minCudaVersion = "11.0";
        maxCudaVersion = "11.8";
        cudnnVersion = null;
        filename = "TensorRT-8.6.1.6.Linux.x86_64-gnu.cuda-11.8.tar.gz";
        hash = "sha256-Fb/mBT1F/uxF7McSOpEGB2sLQ/oENfJC2J3KB3gzd1k=";
      }
      {
        version = "8.6.1.6";
        minCudaVersion = "12.0";
        maxCudaVersion = "12.1";
        cudnnVersion = null;
        filename = "TensorRT-8.6.1.6.Linux.x86_64-gnu.cuda-12.0.tar.gz";
        hash = "sha256-D4FXpfxTKZQ7M4uJNZE3M1CvqQyoEjnNrddYDNHrolQ=";
      }
    ];
  };
in
  options.mkOption {
    description = "A collection of TensorRT packages targeting different platforms";
    inherit example;
    type = types.attrsOf (types.listOf Package.type);
  }
