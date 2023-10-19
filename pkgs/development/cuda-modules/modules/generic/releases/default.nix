{ lib
, config
, ...
}:
let
  inherit (config.generic.types) majorMinorVersion majorMinorPatchBuildVersion;
  inherit (lib) options types;
in
# A package submodule, used as a generic base to define different release types
# (releases are a collection of package).
{
  options = {
    version = options.mkOption {
      description = "The version of the package";
      type = majorMinorPatchBuildVersion;
    };
    minCudaVersion = options.mkOption {
      description = "The minimum CUDA version supported";
      type = majorMinorVersion;
    };
    maxCudaVersion = options.mkOption {
      description = "The maximum CUDA version supported";
      type = majorMinorVersion;
    };
    hash = options.mkOption {
      description = "The hash of the tarball";
      type = types.str;
    };
  };
}
