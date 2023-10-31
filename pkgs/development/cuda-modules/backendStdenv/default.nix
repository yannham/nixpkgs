{
  lib,
  nvccCompatibilities,
  cudaVersion,
  buildPackages,
  overrideCC,
  stdenv,
  wrapCCWith,
}: let
  gccMajorVersion = nvccCompatibilities.${cudaVersion}.gccMaxMajorVersion;
  # We use buildPackages (= pkgsBuildHost) because we look for a gcc that
  # runs on our build platform, and that produces executables for the host
  # platform (= platform on which we deploy and run the downstream packages).
  # The target platform of buildPackages.gcc is our host platform, so its
  # .lib output should be the libstdc++ we want to be writing in the runpaths
  # Cf. https://github.com/NixOS/nixpkgs/pull/225661#discussion_r1164564576
  nixpkgsCompatibleLibstdcxx = buildPackages.gcc.cc.lib;
  nvccCompatibleCC = let
      gcc = buildPackages."gcc${gccMajorVersion}";
      libc = gcc.libc.overrideAttrs ({ patches ? [ ], ...}: {
        patches = patches ++ [ ./dont-use-arm-intrinsics-with-nvcc.patch ];
      });
      # libc_dev = gcc.libc_dev.overrideAttrs ({ patches ? [ ], ...}: {
      #   patches = patches ++ [ ./dont-use-arm-intrinsics-with-nvcc.patch ];
      # });
      # cc_libc_dev = gcc.cc.libc_dev.overrideAttrs ({ patches ? [ ], ...}: {
      #   patches = patches ++ [ ./dont-use-arm-intrinsics-with-nvcc.patch ];
      # });
    in
    (gcc.override {
      inherit libc;
      bintools = gcc.bintools.override { inherit libc; };
      cc = gcc.cc.override { inherit libc; };
    });

  cc =
    wrapCCWith
    {
      inherit (nvccCompatibleCC) libc cc bintools;

      # This option is for clang's libcxx, but we (ab)use it for gcc's libstdc++.
      # Note that libstdc++ maintains forward-compatibility: if we load a newer
      # libstdc++ into the process, we can still use libraries built against an
      # older libstdc++. This, in practice, means that we should use libstdc++ from
      # the same stdenv that the rest of nixpkgs uses.
      # We currently do not try to support anything other than gcc and linux.
      libcxx = nixpkgsCompatibleLibstdcxx;
    };
  cudaStdenv = overrideCC stdenv cc;
  passthruExtra = {
    inherit nixpkgsCompatibleLibstdcxx;
    # cc already exposed
  };
  assertCondition = true;
in
  lib.extendDerivation
  assertCondition
  passthruExtra
  cudaStdenv
