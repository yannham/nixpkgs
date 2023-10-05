{lib, ...}: let
  inherit (lib) options types;
  Package = import ./package.nix {inherit lib;};
  example = {
    linux-aarch64 = {
      cudaArchitectures = [
        "sm_53"
        "sm_61"
        "sm_62"
        "sm_70"
        "sm_72"
        "sm_75"
        "sm_80"
        "sm_86"
        "sm_87"
        "sm_90"
      ];
      dependencies = ["libcublas" "libcublas"];
      neededLibs = [
        "ld-linux-aarch64.so.1"
        "libc.so.6"
        "libcublas.so.12"
        "libcublasLt.so.12"
        "libdl.so.2"
        "libgcc_s.so.1"
        "libm.so.6"
        "libpthread.so.0"
        "librt.so.1"
        "libstdc++.so.6"
      ];
      outputs = {
        hasBin = false;
        hasDev = true;
        hasDoc = false;
        hasLib = true;
        hasSample = false;
        hasStatic = true;
      };
      providedLibs = ["libcublas.so.12" "libcublasLt.so.12" "libnvblas.so.12"];
    };
    linux-ppc64le = {
      cudaArchitectures = [
        "sm_50"
        "sm_52"
        "sm_60"
        "sm_61"
        "sm_70"
        "sm_75"
        "sm_80"
        "sm_86"
        "sm_90"
      ];
      dependencies = ["libcublas" "libcublas"];
      neededLibs = [
        "ld64.so.2"
        "libc.so.6"
        "libcublas.so.12"
        "libcublasLt.so.12"
        "libdl.so.2"
        "libgcc_s.so.1"
        "libm.so.6"
        "libpthread.so.0"
        "librt.so.1"
        "libstdc++.so.6"
      ];
      outputs = {
        hasBin = false;
        hasDev = true;
        hasDoc = false;
        hasLib = true;
        hasSample = false;
        hasStatic = true;
      };
      providedLibs = ["libcublas.so.12" "libcublasLt.so.12" "libnvblas.so.12"];
    };
    linux-sbsa = {
      cudaArchitectures = [
        "sm_50"
        "sm_60"
        "sm_61"
        "sm_70"
        "sm_75"
        "sm_80"
        "sm_86"
        "sm_89"
        "sm_90"
      ];
      dependencies = ["libcublas" "libcublas"];
      neededLibs = [
        "libc.so.6"
        "libcublas.so.12"
        "libcublasLt.so.12"
        "libdl.so.2"
        "libgcc_s.so.1"
        "libm.so.6"
        "libpthread.so.0"
        "librt.so.1"
        "libstdc++.so.6"
      ];
      outputs = {
        hasBin = false;
        hasDev = true;
        hasDoc = false;
        hasLib = true;
        hasSample = false;
        hasStatic = true;
      };
      providedLibs = ["libcublas.so.12" "libcublasLt.so.12" "libnvblas.so.12"];
    };
    linux-x86_64 = {
      cudaArchitectures = [
        "sm_50"
        "sm_60"
        "sm_61"
        "sm_70"
        "sm_75"
        "sm_80"
        "sm_86"
        "sm_89"
        "sm_90"
      ];
      dependencies = ["libcublas" "libcublas"];
      neededLibs = [
        "ld-linux-x86-64.so.2"
        "libc.so.6"
        "libcublas.so.12"
        "libcublasLt.so.12"
        "libdl.so.2"
        "libgcc_s.so.1"
        "libm.so.6"
        "libpthread.so.0"
        "librt.so.1"
        "libstdc++.so.6"
      ];
      outputs = {
        hasBin = false;
        hasDev = true;
        hasDoc = false;
        hasLib = true;
        hasSample = false;
        hasStatic = true;
      };
      providedLibs = ["libcublas.so.12" "libcublasLt.so.12" "libnvblas.so.12"];
    };
    windows-x86_64 = {
      cudaArchitectures = [];
      dependencies = [];
      neededLibs = [];
      outputs = {
        hasBin = true;
        hasDev = true;
        hasDoc = false;
        hasLib = false;
        hasSample = false;
        hasStatic = false;
      };
      providedLibs = [];
    };
  };
in
  options.mkOption {
    description = "A release is an attribute set which includes a mapping from platform to package";
    inherit example;
    type = types.attrsOf Package.type;
  }
