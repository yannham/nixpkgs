final: prev: let
  # NOTE: We use hasAttr throughout instead of the (?) operator because hasAttr does not require
  # us to interpolate our variables into strings (like ${attrName}).
  inherit (builtins) attrNames concatMap getAttr elem hasAttr listToAttrs;
  inherit (final) callPackage;
  inherit (prev) cudaVersion gpus;
  inherit (prev.pkgs) config;
  inherit (prev.lib.attrsets) filterAttrs mapAttrs' nameValuePair optionalAttrs;
  inherit (prev.lib.lists) filter intersectLists map optionals;
  inherit (prev.lib.modules) evalModules;
  inherit (prev.lib.trivial) flip importJSON pipe;

  # Make sure to use the system for the platform we want to run on, so we fetch the correct libs
  inherit (prev.pkgs.stdenv.hostPlatform) system;

  # Manifest files for CUDA redistributables (aka redist). These can be found at
  # https://developer.download.nvidia.com/compute/cuda/redist/
  # Maps a cuda version to the specific version of the manifest.
  cudaVersionMap = {
    "11.4" = "11.4.4";
    "11.5" = "11.5.2";
    "11.6" = "11.6.2";
    "11.7" = "11.7.1";
    "11.8" = "11.8.0";
    "12.0" = "12.0.1";
    "12.1" = "12.1.1";
    "12.2" = "12.2.2";
  };

  # Check if the current CUDA version is supported.
  cudaVersionMappingExists = hasAttr cudaVersion cudaVersionMap;

  # fullCudaVersion : String
  fullCudaVersion = cudaVersionMap.${cudaVersion};

  evaluatedModules = evalModules {
    modules = [
      ./modules/feature_manifest
      ./modules/redistrib_manifest
      {
        redistrib_manifest = importJSON ./manifests/redistrib_${fullCudaVersion}.json;
        feature_manifest = importJSON ./manifests/feature_${fullCudaVersion}.json;
      }
    ];
  };

  inherit (evaluatedModules.config) feature_manifest redistrib_manifest;

  # We need to find out whether we're building any Jetson capabilities so we know whether to swap
  # out the default `linux-sbsa` redist (for server-grade ARM chips) with the `linux-aarch64`
  # redist (which is for Jetson devices).
  # Get the compute capabilities of all Jetson devices.
  jetsonComputeCapabilities = pipe gpus [
    (filter (getAttr "isJetson"))
    (map (getAttr "computeCapability"))
  ];
  # Find the intersection with the user-specified list of cudaCapabilities.
  # NOTE: Jetson devices are never built by default because they cannot be targeted along
  # non-Jetson devices and require an aarch64 host platform. As such, if they're present anywhere,
  # they must be in the user-specified config.cudaCapabilities.
  # NOTE: We don't need to worry about mixes of Jetson and non-Jetson devices here -- there's
  # sanity-checking for all that in cudaFlags.
  jetsonTargets = intersectLists jetsonComputeCapabilities (config.cudaCapabilities or []);

  # Maps NVIDIA redist arch to Nix arch.
  # NOTE: We swap out the default `linux-sbsa` redist (for server-grade ARM chips) with the
  # `linux-aarch64` redist (which is for Jetson devices) if we're building any Jetson devices.
  # Since both are based on aarch64, we can only have one or the other, otherwise there's an
  # ambiguity as to which should be used.
  redistArchToNixSystem =
    {
      # Available under pkgsCross.powernv
      linux-ppc64le = "powerpc64le-linux";
      # Available under pkgsCross.x86_64-multiplatform
      linux-x86_64 = "x86_64-linux";
      # Available under pkgsCross.mingwW64
      windows-x86_64 = "x86_64-windows";
    }
    // (
      if jetsonTargets != []
      then {
        # linux-aarch64 is Linux for Tegra (Jetson)
        # Available under pkgsCross.aarch64-embedded
        linux-aarch64 = "aarch64-linux";
      }
      else {
        # linux-sbsa is Linux for ARM (server-grade)
        # Available under pkgsCross.aarch64-multiplatform
        linux-sbsa = "aarch64-linux";
      }
    );

  # Builder function which builds a single redist package for a given platform
  # or returns null if the package is not supported.
  # buildRedistPackage : PackageName -> List Derivation
  buildRedistPackage = pname: let
    # Get the redist architectures the package provides distributables for
    platformsSupportedByPackage = attrNames redistrib_manifest.${pname};
    supportedNixSystemToRedistArch =
      mapAttrs' (flip nameValuePair)
      (filterAttrs (name: _value: elem name platformsSupportedByPackage) redistArchToNixSystem);

    # Check if supported
    isSupported = hasAttr system supportedNixSystemToRedistArch;
    redistArch = supportedNixSystemToRedistArch.${system};

    # Build the derivation
    drv = callPackage ./generic.nix {
      inherit pname;
      # TODO(@connorbaker): We currently discard the license attribute.
      inherit (redistrib_manifest.${pname}) version;
      description = redistrib_manifest.${pname}.name;
      platforms = attrNames supportedNixSystemToRedistArch;
      redistrib_package = redistrib_manifest.${pname}.${redistArch};
      feature_package = feature_manifest.${pname}.${redistArch};
    };
  in
    optionals isSupported [(nameValuePair pname drv)];

  # concatMap provides us an easy way to filter out packages for unsupported platforms.
  # We wrap the buildRedistPackage call in a list to prevent errors when the package is not
  # supported (by returning an empty list).
  redistPackages =
    optionalAttrs
    cudaVersionMappingExists
    (listToAttrs (concatMap buildRedistPackage (attrNames feature_manifest)));
in
  redistPackages
