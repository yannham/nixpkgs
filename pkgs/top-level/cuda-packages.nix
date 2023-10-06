{
  config,
  cudaVersion,
  lib,
  pkgs,
  hostPlatform,
  generateSplicesForMkScope,
  newScope,
}: let
  inherit (lib) customisation fixedPoints versions;
  # Notes:
  #
  # Silvan (Tweag) covered some things on recursive attribute sets in the Nix Hour:
  # https://www.youtube.com/watch?v=BgnUFtd1Ivs
  #
  # I highly recommend watching it.
  #
  # In any of the extensions, trying to use attribute defined in
  # passthruFunction which is built via callPackage will cause infinite recursion.
  #
  # To my knowledge (@connorbaker) the only thing that is acceptable to take from
  # `final` while in an extension is `callPackage`.
  #
  # Because we want to be able to use gpus, nvccCompatibilities, flags, etc. in
  # the extensions, we have to pass them in via passthruFunction without using
  # `final` to create them.
  #
  # TODO(@connorbaker): Does this mean that overriding `cudaVersion` on `cudaPackages`
  # will not work?
  # TODO(@connorbaker): Including CUDNN in the extensions causes infinite recursion.
  # The CUDA extension seems fine, and though it uses flags as well (which seems to be
  # the source of the infinite recursion), it doesn't cause it. Perhaps this is because
  # the usage of flags in the CUDA extension occurs within the generic builder, while
  # the usage of flags in the CUDNN extension occurs directly in the extension.
  passthruFunction = final: {
    inherit cudaVersion pkgs lib;
    cudaMajorVersion = versions.major final.cudaVersion;
    cudaMajorMinorVersion = versions.majorMinor final.cudaVersion;
    addBuildInputs = drv: buildInputs:
      drv.overrideAttrs (oldAttrs: {
        buildInputs = (oldAttrs.buildInputs or []) ++ buildInputs;
      });

    # Backbone of the cudaPackages scope
    gpus = builtins.import ../development/cuda-modules/gpus.nix;
    nvccCompatibilities = builtins.import ../development/cuda-modules/nvccCompatibilities.nix;
    flags = final.callPackage ../development/cuda-modules/flags.nix {};

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
  };

  cutensorExtension = final: prev: let
    ### CuTensor
    buildCuTensorPackage = final.callPackage ../development/cuda-modules/cutensor/generic.nix;

    cuTensorVersions = {
      "1.2.2.5" = {
        hash = "sha256-lU7iK4DWuC/U3s1Ct/rq2Gr3w4F2U7RYYgpmF05bibY=";
      };
      "1.5.0.3" = {
        hash = "sha256-T96+lPC6OTOkIs/z3QWg73oYVSyidN0SVkBWmT9VRx0=";
      };
    };

    inherit (final) cudaMajorMinorVersion;

    cutensor = buildCuTensorPackage rec {
      version =
        if cudaMajorMinorVersion == "10.1"
        then "1.2.2.5"
        else "1.5.0.3";
      inherit (cuTensorVersions.${version}) hash;
    };
  in {inherit cutensor;};

  composedExtension = fixedPoints.composeManyExtensions [
    (import ../development/cuda-modules/setup-hooks/extension.nix)
    (import ../development/cuda-modules/cuda/extension.nix)
    (import ../development/cuda-modules/cuda/overrides.nix)
    (import ../development/cuda-modules/cudnn/extension.nix)
    # (import ../development/cuda-modules/tensorrt/extension.nix)
    # (import ../test/cuda/cuda-samples/extension.nix)
    # (import ../test/cuda/cuda-library-samples/extension.nix)
    # cutensorExtension
  ];

  cudaPackages = customisation.makeScope newScope (fixedPoints.extends composedExtension passthruFunction);
in
  cudaPackages
