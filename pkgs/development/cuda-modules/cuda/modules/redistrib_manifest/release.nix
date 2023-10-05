{lib, ...}: let
  inherit (lib) options types;
  Package = import ./package.nix {inherit lib;};
  example = {
    name = "CXX Core Compute Libraries";
    license = "CUDA Toolkit";
    version = "11.5.62";
    linux-x86_64 = {
      relative_path = "cuda_cccl/linux-x86_64/cuda_cccl-linux-x86_64-11.5.62-archive.tar.xz";
      sha256 = "bbe633d6603d5a96a214dcb9f3f6f6fd2fa04d62e53694af97ae0c7afe0121b0";
      md5 = "e5deef4f6cb71f14aac5be5d5745dafe";
      size = "960968";
    };
    linux-ppc64le = {
      relative_path = "cuda_cccl/linux-ppc64le/cuda_cccl-linux-ppc64le-11.5.62-archive.tar.xz";
      sha256 = "f5301a213878c7afbc67da03b09b27e1cb92178483042538f1585df09407214a";
      md5 = "9c3200a20b10bebcdde87367128d36d9";
      size = "960940";
    };
    linux-sbsa = {
      relative_path = "cuda_cccl/linux-sbsa/cuda_cccl-linux-sbsa-11.5.62-archive.tar.xz";
      sha256 = "a4faf04025bdaf5b7871ad43f50cbe2ca10baf8665b17b78d32c50aa8ba7ae8b";
      md5 = "229a13fbe8426da383addf9ee9168984";
      size = "960660";
    };
    windows-x86_64 = {
      relative_path = "cuda_cccl/windows-x86_64/cuda_cccl-windows-x86_64-11.5.62-archive.zip";
      sha256 = "2a44c359d523317d1c93ba6568ace3c088c83026e2e40d34a97fccd876466b4b";
      md5 = "93604e9c00b8fbc31827c7a82c0894c2";
      size = "2459582";
    };
  };
in
  options.mkOption {
    description = "A release is an attribute set which includes a mapping from platform to package";
    inherit example;
    type = types.submodule {
      # Allow any attribute name as these will be the platform names
      freeformType = types.attrsOf Package.type;
      options = {
        name = options.mkOption {
          description = "The full name of the package";
          example = "CXX Core Compute Libraries";
          type = types.str;
        };
        license = options.mkOption {
          description = "The license of the package";
          example = "CUDA Toolkit";
          type = types.str;
        };
        license_path = options.mkOption {
          description = "The path to the license of the package";
          example = "cuda_cccl/LICENSE.txt";
          default = null;
          type = types.nullOr types.str;
        };
        version = options.mkOption {
          description = "The version of the package";
          example = "11.5.62";
          type = types.str;
        };
      };
    };
  }
