{
  # callPackage-provided arguments
  lib,
  cudaVersion,
  flags,
  hostPlatform,
  # Expected to be passed by the caller
  mkVersionedPackageName,
  pname,
}: let
  inherit (lib) attrsets lists modules strings;

  evaluatedModules = modules.evalModules {
    modules = [
      ./modules
      (./. + "/${pname}/releases.nix") # Provides ${pname}.releases attribute
    ];
  };

  # NOTE: Important types:
  # - Releases: ../modules/${pname}/releases/releases.nix
  # - Package: ../modules/${pname}/releases/package.nix

  # All releases across all platforms
  # See ../modules/${pname}/releases/releases.nix
  allReleases = evaluatedModules.config.${pname}.releases;

  # Compute versioned attribute name to be used in this package set
  # Patch version changes should not break the build, so we only use major and minor
  # computeName :: Package -> String
  computeName = {version, ...}: mkVersionedPackageName pname version;

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

  # A function which takes the `final` overlay and the `package` being built and returns
  # a function to be consumed via `overrideAttrs`.
  overrideAttrsFixupFn = final: package:
    final.callPackage (./. + "/${pname}/fixup.nix") {
      inherit final cudaVersion mkVersionedPackageName package;
    };

  # The redistribRelease is only used in ./genericManifestBuilder.nix for the package version
  # and the package description (which NVIDIA's manifest calls the "name").
  # It's also used for fetching the source, but we override that since we can't
  # re-use that portion of the functionality (different URLs, etc.).
  # The featureRelease is used to populate meta.platforms (by way of looking at the attribute names)
  # and to determine the outputs of the package.
  # getShims :: {package, redistArch} -> AttrSet
  getShims = builtins.import (./. + "/${pname}/shims.nix");

  extension = final: _: let
    # Builds our package into derivation and wraps it in a nameValuePair, where the name is the versioned name
    # of the package.
    buildPackage = package: let
      shims = getShims {inherit package redistArch;};
      name = computeName package;
      drv = final.callPackage ./genericManifestBuilder.nix {
        inherit pname;
        redistName = pname;
        inherit (shims) redistribRelease featureRelease;
      };
      fixedDrv = drv.overrideAttrs (overrideAttrsFixupFn final package);
    in
      attrsets.nameValuePair name fixedDrv;

    # versionedDerivations :: AttrSet Derivation
    versionedDerivations = builtins.listToAttrs (lists.map buildPackage newestToOldestSupportedPackage);

    defaultDerivation = attrsets.optionalAttrs (versionedDerivations != {}) {
      ${pname} = versionedDerivations.${nameOfNewest};
    };
  in
    versionedDerivations // defaultDerivation;
in
  extension
