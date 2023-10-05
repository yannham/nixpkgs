{lib, ...}: let
  inherit (lib) options types;

  CudaArch = import ./cuda-arch.nix {inherit lib;};
  LibSoName = import ./lib-so-name.nix {inherit lib;};
  Outputs = import ./outputs.nix {inherit lib;};

  example = {
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
in
  options.mkOption {
    description = "A package in the manifest";
    inherit example;
    type = types.submodule {
      options = {
        cudaArchitectures = options.mkOption {
          description = ''
            The CUDA architectures supported by the package.

            This is either a list of architectures or a mapping from subdirectory name to list of architectures.
          '';
          type = types.oneOf [
            (types.listOf CudaArch.type)
            (types.attrsOf (types.listOf CudaArch.type))
          ];
        };
        dependencies = options.mkOption {
          description = ''
            The dependencies of the package.

            This is either a list of dependencies or a mapping from subdirectory name to list of dependencies.
          '';
          example = ["libcublas"];
          type = types.oneOf [
            (types.listOf types.str)
            (types.attrsOf (types.listOf types.str))
          ];
        };
        neededLibs = options.mkOption {
          description = ''
            The libraries needed by the package.

            This is either a list of libraries or a mapping from subdirectory name to list of libraries.
          '';
          example = ["libcublas.so.11"];
          type = types.oneOf [
            (types.listOf LibSoName.type)
            (types.attrsOf (types.listOf LibSoName.type))
          ];
        };
        outputs = Outputs;
        providedLibs = options.mkOption {
          description = ''
            The libraries provided by the package.

            This is either a list of libraries or a mapping from subdirectory name to list of libraries.
          '';
          example = ["libcublas.so.11"];
          type = types.oneOf [
            (types.listOf LibSoName.type)
            (types.attrsOf (types.listOf LibSoName.type))
          ];
        };
      };
    };
  }
