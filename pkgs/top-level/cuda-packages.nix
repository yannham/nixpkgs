{
  callPackage,
  cudaVersion,
  lib,
  newScope,
  pkgs,
}: let
  inherit (lib) customisation fixedPoints strings versions;
  # Notes:
  #
  # Silvan (Tweag) covered some things on recursive attribute sets in the Nix Hour:
  # https://www.youtube.com/watch?v=BgnUFtd1Ivs
  #
  # I highly recommend watching it.
  #
  # Most helpful comment regarding recursive attribute sets:
  # 
  # https://github.com/NixOS/nixpkgs/pull/256324#issuecomment-1749935979
  # 
  # To summarize:
  # 
  # - `prev` should only be used to access attributes which are going to be overriden.
  # - `final` should only be used to access `callPackage` to build new packages.
  # - Attribute names should be computable without relying on `final`.
  #   - Extensions should take arguments to build attribute names before relying on `final`.
  # 
  # TODO(@connorbaker): A big problem with this is that the attribute names of the CUDA extension
  # depend on `cudaVersion`, as the version determines which packages are available.
  # In this first iteration, we're going to structure these extensions so they produce attribute sets
  # mapping package name (computed using the `cudaVersion` from the top of this file, not from `final`)
  # to package derivation.
  # I don't know how this will interact with overrides.
  # Backbone
  gpus = builtins.import ../development/cuda-modules/gpus.nix;
  nvccCompatibilities = builtins.import ../development/cuda-modules/nvccCompatibilities.nix;
  flags = callPackage ../development/cuda-modules/flags.nix {
    inherit cudaVersion gpus;
  };
  passthruFunction = final: {
    # TODO(@connorbaker): `flags` doesn't depend on `final.gpus` or `final.cudaVersion`.
    inherit lib pkgs;
    inherit gpus nvccCompatibilities flags cudaVersion;

    # TODO(@connorbaker): `cudaFlags` is an alias for `flags` which should be removed in the future.
    cudaFlags = flags;

    # Exposed as cudaPackages.backendStdenv.
    # This is what nvcc uses as a backend,
    # and it has to be an officially supported one (e.g. gcc11 for cuda11).
    #
    # It, however, propagates current stdenv's libstdc++ to avoid "GLIBCXX_* not found errors"
    # when linked with other C++ libraries.
    # E.g. for cudaPackages_11_8 we use gcc11 with gcc12's libstdc++
    # Cf. https://github.com/NixOS/nixpkgs/pull/218265 for context
    backendStdenv = final.callPackage ../development/cuda-modules/backendStdenv.nix {};

    # Loose packages
    cudatoolkit = final.callPackage ../development/cuda-modules/cudatoolkit {};
    nccl = final.callPackage ../development/cuda-modules/nccl {};
    nccl-tests = final.callPackage ../development/cuda-modules/nccl-tests {};
    saxpy = final.callPackage ../development/cuda-modules/saxpy {};
    
    # TODO(@connorbaker): These don't rely on cudaVersion defined in `cudaPackagesAttrs`.
    # Will overrides work?
    cudaMajorVersion = versions.major cudaVersion;
    cudaMajorMinorVersion = versions.majorMinor cudaVersion;
  };

  
  # NOTE(@connorbaker):
  # Assume we refactored ../development/cuda-modules/setup-hooks/extension.nix so that, instead of
  #   final: _:
  # it took 
  #   {callPackage}:
  # as an argument. Then, if we wanted to merge the setup-hooks packages with cudaPackages, we could do this:
  #   // (builtins.import ../development/cuda-modules/setup-hooks {inherit (final) callPackage; })
  # But we could not do this:
  #   // (final.callPackage ../development/cuda-modules/setup-hooks {})
  # as it would result in infinite recursion. Why? The latter requires using `final.callPackage` to
  # compute the attribute names while the former does not.

  mkVersionedPackageName = name: version:
    strings.concatStringsSep "_" [name (strings.replaceStrings ["."] ["_"] (versions.majorMinor version))];

  composedExtension = fixedPoints.composeManyExtensions [
    (import ../development/cuda-modules/setup-hooks/extension.nix)
    (callPackage ../development/cuda-modules/cuda/extension.nix {
      inherit cudaVersion;
    })
    (callPackage ../development/cuda-modules/cuda/overrides.nix {
      inherit cudaVersion;
    })
    (callPackage ../development/cuda-modules/genericMultiplexExtension.nix {
      inherit cudaVersion flags mkVersionedPackageName;
      pname = "cudnn";
    })
    (callPackage ../development/cuda-modules/cutensor/extension.nix {
      inherit cudaVersion flags mkVersionedPackageName;
    })
    (callPackage ../development/cuda-modules/genericMultiplexExtension.nix {
      inherit cudaVersion flags mkVersionedPackageName;
      pname = "tensorrt";
    })
    # (import ../test/cuda/cuda-samples/extension.nix)
    # (import ../test/cuda/cuda-library-samples/extension.nix)
  ];

  cudaPackages = customisation.makeScope newScope (fixedPoints.extends composedExtension passthruFunction);
in
  cudaPackages
