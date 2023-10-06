# Support matrix can be found at
# https://docs.nvidia.com/deeplearning/cudnn/archives/cudnn-880/support-matrix/index.html
final: prev: let
  inherit (final) callPackage;
  inherit (prev) cudaVersion flags;
  inherit (prev.pkgs) hostPlatform;
  inherit (prev.lib) attrsets lists modules versions strings;

  evaluatedModules = modules.evalModules {
    modules = [
      ../modules
      ./releases.nix # Provides cudnn.releases attribute, no need to nest it here
    ];
  };

  # NOTE: Important types:
  # - Releases: ../modules/cudnn/releases/releases.nix
  # - Package: ../modules/cudnn/releases/package.nix

  # All CUDNN releases across all platforms
  # See ../modules/cudnn/releases/releases.nix
  allCudnnReleases = evaluatedModules.config.cudnn.releases;

  # Compute versioned attribute name to be used in this package set
  # Patch version changes should not break the build, so we only use major and minor
  # computeName :: Package -> String
  computeName = package: "cudnn_${strings.replaceStrings ["."] ["_"] (versions.majorMinor package.version)}";

  # Check whether a CUDNN package supports our CUDA version
  # isSupported :: Package -> Bool
  isSupported = package:
    strings.versionAtLeast cudaVersion package.minCudaVersion
    && strings.versionAtLeast package.maxCudaVersion cudaVersion;

  # Get all of the packages for our given platform.
  redistArch = flags.getRedistArch hostPlatform.system;

  # All the packages for our platform.
  # cudnnPackages :: List (AttrSet Packages)
  cudnnPackages = builtins.filter isSupported (allCudnnReleases.${redistArch} or []);

  # newestToOldestCudnnPackages :: List (AttrSet Packages)
  newestToOldestCudnnPackages = lists.reverseList cudnnPackages;

  # buildCudnnPackage :: Package -> Derivation
  buildCudnnPackage = package: {
    name = computeName package;
    value = callPackage ./generic.nix {
      inherit package;
      platforms = lists.map (flags.getNixSystem) (builtins.attrNames allCudnnReleases);
      useCudatoolkitRunfile = strings.versionOlder cudaVersion "11.3.999";
    };
  };

  # allCudnnDerivations :: AttrSet Derivation
  versionedCudnnDerivations = builtins.listToAttrs (lists.map buildCudnnPackage newestToOldestCudnnPackages);

  # allCudnnDerivations :: AttrSet Derivation
  allCudnnDerivations = let
    nameOfNewest = computeName (builtins.head newestToOldestCudnnPackages);
    containsDefault = attrsets.optionalAttrs (versionedCudnnDerivations != {}) {
      cudnn = versionedCudnnDerivations.${nameOfNewest};
    };
  in
    versionedCudnnDerivations // containsDefault;
in
  allCudnnDerivations
