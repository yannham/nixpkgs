{ cudaVersion
, lib
, pkgs
}:

let
  inherit (lib) customisation fixedPoints versions;

  scope = customisation.makeScope pkgs.newScope (final: {
    # Entries necessary to build the finalized cudaPackages package set.
    inherit cudaVersion lib pkgs;
    gpus = builtins.import ../development/cuda-modules/gpus.nix;
    nvccCompatibilities = builtins.import ../development/cuda-modules/nvccCompatibilities.nix;
    flags = final.callPackage ../development/cuda-modules/flags.nix { };
    # Exposed as cudaPackages.backendStdenv.
    # This is what nvcc uses as a backend,
    # and it has to be an officially supported one (e.g. gcc11 for cuda11).
    #
    # It, however, propagates current stdenv's libstdc++ to avoid "GLIBCXX_* not found errors"
    # when linked with other C++ libraries.
    # E.g. for cudaPackages_11_8 we use gcc11 with gcc12's libstdc++
    # Cf. https://github.com/NixOS/nixpkgs/pull/218265 for context
    backendStdenv =
      let
        gccMajorVersion = final.nvccCompatibilities.${cudaVersion}.gccMaxMajorVersion;
        # We use buildPackages (= pkgsBuildHost) because we look for a gcc that
        # runs on our build platform, and that produces executables for the host
        # platform (= platform on which we deploy and run the downstream packages).
        # The target platform of buildPackages.gcc is our host platform, so its
        # .lib output should be the libstdc++ we want to be writing in the runpaths
        # Cf. https://github.com/NixOS/nixpkgs/pull/225661#discussion_r1164564576
        nixpkgsCompatibleLibstdcxx = final.pkgs.buildPackages.gcc.cc.lib;
        nvccCompatibleCC = final.pkgs.buildPackages."gcc${gccMajorVersion}".cc;
      in
      final.callPackage ../development/cuda-modules/backendStdenv.nix {
        inherit nixpkgsCompatibleLibstdcxx nvccCompatibleCC;
      };

    # Here we put package set configuration and utility functions.
    cudaMajorVersion = versions.major final.cudaVersion;
    cudaMajorMinorVersion = lib.versions.majorMinor final.cudaVersion;
    addBuildInputs = drv: buildInputs: drv.overrideAttrs (oldAttrs: {
      buildInputs = (oldAttrs.buildInputs or [ ]) ++ buildInputs;
    });
  });

  cutensorExtension = final: prev:
    let
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

      inherit (final) cudaMajorMinorVersion cudaMajorVersion;

      cutensor = buildCuTensorPackage rec {
        version = if cudaMajorMinorVersion == "10.1" then "1.2.2.5" else "1.5.0.3";
        inherit (cuTensorVersions.${version}) hash;
      };
    in
    { inherit cutensor; };

  extraPackagesExtension = final: _: {
    cudatoolkit = final.callPackage ../development/cuda-modules/cudatoolkit { };
    nccl = final.callPackage ../development/cuda-modules/nccl { };
    nccl-tests = final.callPackage ../development/cuda-modules/nccl-tests { };
    saxpy = final.callPackage ../development/cuda-modules/saxpy { };
  };

  composedExtension = fixedPoints.composeManyExtensions ([
    (import ../development/cuda-modules/hooks/extension.nix)
    extraPackagesExtension
    (import ../development/cuda-modules/cuda/extension.nix)
    (import ../development/cuda-modules/cuda/overrides.nix)
    (import ../development/cuda-modules/cudnn/extension.nix)
    # (import ../development/cuda-modules/tensorrt/extension.nix)
    # (import ../test/cuda/cuda-samples/extension.nix)
    # (import ../test/cuda/cuda-library-samples/extension.nix)
    cutensorExtension
  ]);

in
(scope.overrideScope composedExtension)
