{
  # callPackage-provided arguments
  lib,
  cudaVersion,
  flags,
  hostPlatform,
  # Expected to be passed by the caller
  mkVersionedPackageName,
  redistName,
}: let
  inherit (lib) attrsets lists modules strings;

  evaluatedModules = modules.evalModules {
    modules = [
      ./modules
      (./. + "/${redistName}/releases.nix") # Provides ${redistName}.releases attribute
    ];
  };

  # NOTE: Important types:
  # - Releases: ../modules/${redistName}/releases/releases.nix
  # - Package: ../modules/${redistName}/releases/package.nix

  # All releases across all platforms
  # See ../modules/${redistName}/releases/releases.nix
  allReleases = evaluatedModules.config.${redistName}.releases;

  # Compute versioned attribute name to be used in this package set
  # Patch version changes should not break the build, so we only use major and minor
  # computeName :: Package -> String
  computeName = {version, ...}: mkVersionedPackageName redistName version;

  # Check whether a package supports our CUDA version
  # isSupported :: Package -> Bool
  isSupported = package:
    strings.versionAtLeast cudaVersion package.minCudaVersion
    && strings.versionAtLeast package.maxCudaVersion cudaVersion;

  # Get all of the packages for our given platform.
  redistArch = flags.getRedistArch hostPlatform.system;

  # All the supported packages we can build for our platform.
  # supportedPackages :: List (AttrSet Packages)
  supportedPackages = builtins.filter isSupported (allReleases.${redistArch} or []);

  # newestToOldestSupportedPackage :: List (AttrSet Packages)
  newestToOldestSupportedPackage = lists.reverseList supportedPackages;

  nameOfNewest = computeName (builtins.head newestToOldestSupportedPackage);

  genericBuilderFixupFn = final: package:
    final.callPackage (./. + "/${redistName}/genericMultiplexBuilderFixup.nix") {
      inherit final cudaVersion mkVersionedPackageName package;
    };

  extension = final: _: let
    buildPackage = package: {
      name = computeName package;
      value = let
        drv = final.callPackage ./genericMultiplexBuilder.nix {
          inherit package;
          pname = redistName;
          platforms = lists.map (flags.getNixSystem) (builtins.attrNames allReleases);
        };
      in
        genericBuilderFixupFn final package drv;
    };
    # versionedDerivations :: AttrSet Derivation
    versionedDerivations = builtins.listToAttrs (lists.map buildPackage newestToOldestSupportedPackage);
    defaultDerivation = attrsets.optionalAttrs (versionedDerivations != {}) {
      ${redistName} = versionedDerivations.${nameOfNewest};
    };
  in
    versionedDerivations // defaultDerivation;
in
  extension
