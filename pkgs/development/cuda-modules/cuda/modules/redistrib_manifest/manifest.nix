{lib, ...}: let
  inherit (lib) options types;
  Release = import ./release.nix {inherit lib;};
  example = {
    release_date = "2023-08-29";
    release_label = "12.2.2";
    release_product = "cuda";
    cuda_cccl = {
      name = "CXX Core Compute Libraries";
      license = "CUDA Toolkit";
      license_path = "cuda_cccl/LICENSE.txt";
      version = "12.2.140";
      linux-x86_64 = {
        relative_path = "cuda_cccl/linux-x86_64/cuda_cccl-linux-x86_64-12.2.140-archive.tar.xz";
        sha256 = "90fa538e41f7f444896b61d573d502ea501f44126f8ff64442987e192a8a39dd";
        md5 = "00ea502586a8c17e086292690d6680d6";
        size = "1150676";
      };
      linux-ppc64le = {
        relative_path = "cuda_cccl/linux-ppc64le/cuda_cccl-linux-ppc64le-12.2.140-archive.tar.xz";
        sha256 = "9503cf76dcb0ca16e8b29771916fc41100906c1c38cfc1c055ab07046cf6a5db";
        md5 = "426d244e235592832920527e6eec817e";
        size = "1150768";
      };
      linux-sbsa = {
        relative_path = "cuda_cccl/linux-sbsa/cuda_cccl-linux-sbsa-12.2.140-archive.tar.xz";
        sha256 = "f28c327c745030e16aa9f41526401d169f5646ffe3de3f1ac533d91929f44e5c";
        md5 = "2f74c30cc6309a609af2ac980f02b5c6";
        size = "1150316";
      };
      windows-x86_64 = {
        relative_path = "cuda_cccl/windows-x86_64/cuda_cccl-windows-x86_64-12.2.140-archive.zip";
        sha256 = "6a83fda78793e5328d89ef0258d2f26bba5177ff118b6657a7be38ffd89f10b0";
        md5 = "aa623b334362cb9ad2f2032a40cd771b";
        size = "3044697";
      };
      linux-aarch64 = {
        relative_path = "cuda_cccl/linux-aarch64/cuda_cccl-linux-aarch64-12.2.140-archive.tar.xz";
        sha256 = "ca3956b1528b4b4a637f5e9f2d708e955f23ae4510f7aca4fd30080e3329fb02";
        md5 = "fa7040730790c8bfe0e9eea6163b8e6a";
        size = "1151012";
      };
    };
    cuda_compat = {
      name = "CUDA compat L4T";
      license = "CUDA Toolkit";
      license_path = "cuda_compat/LICENSE.txt";
      version = "12.2.34086590";
      linux-aarch64 = {
        relative_path = "cuda_compat/linux-aarch64/cuda_compat-linux-aarch64-12.2.34086590-archive.tar.xz";
        sha256 = "fd59f6c5f6c670a62b7bac75d74db29a26f3e3703f0e5035cf30f7b6cfd5a74d";
        md5 = "2dc0b8c8bcbab6cb689ee781c3f10dd5";
        size = "18680292";
      };
    };
  };
in
  options.mkOption {
    description = "A redistributable manifest is an attribute set which includes a mapping from package name to release";
    inherit example;
    type = types.submodule {
      # Allow any attribute name as these will be the package names
      freeformType = types.attrsOf Release.type;
      options = {
        release_date = options.mkOption {
          description = "The release date of the manifest";
          type = types.nullOr types.str;
          default = null;
          example = "2023-08-29";
        };
        release_label = options.mkOption {
          description = "The release label of the manifest";
          type = types.nullOr types.str;
          default = null;
          example = "12.2.2";
        };
        release_product = options.mkOption {
          example = "cuda";
          description = "The release product of the manifest";
          type = types.nullOr types.str;
          default = null;
        };
      };
    };
  }
