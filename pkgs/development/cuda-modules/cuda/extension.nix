final: prev: let
  inherit (final) callPackage;
  inherit (prev) cudaVersion;
  inherit (prev.lib) attrsets modules trivial;

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
  cudaVersionMappingExists = builtins.hasAttr cudaVersion cudaVersionMap;

  # fullCudaVersion : String
  fullCudaVersion = cudaVersionMap.${cudaVersion};

  evaluatedModules = modules.evalModules {
    modules = [
      ../modules
      # We need to nest the manifests in a config.cuda.manifests attribute so the
      # module system can evaluate them.
      {
        cuda.manifests = {
          redistrib = trivial.importJSON ./manifests/redistrib_${fullCudaVersion}.json;
          feature = trivial.importJSON ./manifests/feature_${fullCudaVersion}.json;
        };
      }
    ];
  };

  # Generally we prefer to do things involving getting attribute names with feature_manifest instead
  # of redistrib_manifest because the feature manifest will have *only* the redist architecture
  # names as the keys, whereas the redistrib manifest will also have things like version, name, license,
  # and license_path.
  featureManifest = evaluatedModules.config.cuda.manifests.feature;
  redistribManifest = evaluatedModules.config.cuda.manifests.redistrib;

  # Builder function which builds a single redist package for a given platform
  # or returns null if the package is not supported.
  # buildRedistPackage : PackageName -> null | Derivation
  buildRedistPackage = pname:
    callPackage ./generic.nix {
      inherit pname;
      # TODO(@connorbaker): We currently discard the license attribute.
      inherit (redistribManifest.${pname}) version;
      description = redistribManifest.${pname}.name;
      # We pass the whole release to the builder because it has logic to handle
      # the case we're trying to build on an unsupported platform.
      redistribRelease = redistribManifest.${pname};
      featureRelease = featureManifest.${pname};
    };

  redistPackages = trivial.pipe featureManifest [
    # Get all the package names
    builtins.attrNames
    # Build the redist packages
    (trivial.flip attrsets.genAttrs buildRedistPackage)
    # Wrap the whole thing in an optionalAttrs so we can return an empty set if the CUDA version
    # is not supported.
    (attrsets.optionalAttrs cudaVersionMappingExists)
  ];
in
  redistPackages
