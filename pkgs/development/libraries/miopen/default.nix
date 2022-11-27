{ lib
, stdenv
, fetchFromGitHub
, writeScript
, pkg-config
, cmake
, rocm-cmake
, rocm-runtime
, rocm-device-libs
, rocm-comgr
, rocm-opencl-runtime
, rocblas
, rocmlir
, hip
, clang
, clang-ocl
, llvm
, miopengemm
, composable_kernel
, half
, boost
, sqlite
, bzip2
, texlive ? null
, doxygen ? null
, sphinx ? null
, python3Packages ? null
, zlib ? null
, fetchurl ? null
, buildDocs ? false
, buildTests ? false
# LFS isn't working, so we will manually fetch these
# This isn't strictly required, but is recommended
# https://github.com/ROCmSoftwarePlatform/MIOpen/issues/1373
, fetchKDBs ? true
, useOpenCL ? false
}:

assert buildDocs -> texlive != null;
assert buildDocs -> doxygen != null;
assert buildDocs -> sphinx != null;
assert buildDocs -> python3Packages != null;
assert buildTests -> zlib != null;
assert fetchKDBs -> fetchurl != null;

let
  latex = lib.optionalAttrs buildDocs (texlive.combine {
    inherit (texlive) scheme-small
    latexmk
    tex-gyre
    fncychap
    wrapfig
    capt-of
    framed
    needspace
    tabulary
    varwidth
    titlesec;
  });

  kdbs = lib.optionalAttrs fetchKDBs import ./deps.nix {
    inherit fetchurl;
    mirror = "https://repo.radeon.com/rocm/miopen-kernel/rel-5.0";
  };
in stdenv.mkDerivation (finalAttrs: {
  pname = "miopen";
  # We have to manually specify the repoVersion for now
  # Find the github release or `-- MIOpen_VERSION= X.X.X` in the build log
  repoVersion = "2.18.0";
  rocmVersion = "5.3.3";
  version = "${finalAttrs.repoVersion}-${finalAttrs.rocmVersion}";

  outputs = [
    "out"
  ] ++ lib.optionals buildDocs [
    "doc"
  ] ++ lib.optionals buildTests [
    "test"
  ];

  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "MIOpen";
    rev = "rocm-${finalAttrs.rocmVersion}";
    hash = "sha256-5/JitdGJ0afzK4pGOOywRLsB3/Thc6/71sRkKIxf2Lg=";
  };

  nativeBuildInputs = [
    pkg-config
    cmake
    rocm-cmake
    hip
    clang
    llvm
  ];

  buildInputs = [
    rocm-runtime
    rocm-device-libs
    rocm-comgr
    rocm-opencl-runtime
    rocblas
    rocmlir
    clang-ocl
    miopengemm
    composable_kernel
    half
    boost
    sqlite
    bzip2
  ] ++ lib.optionals buildDocs [
    latex
    doxygen
    sphinx
    python3Packages.sphinx_rtd_theme
    python3Packages.breathe
    python3Packages.myst-parser
  ] ++ lib.optionals buildTests [
    zlib
  ];

  cmakeFlags = [
    "-DMIOPEN_USE_MIOPENGEMM=ON"
    # Manually define CMAKE_INSTALL_<DIR>
    # See: https://github.com/NixOS/nixpkgs/pull/197838
    "-DCMAKE_INSTALL_BINDIR=bin"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ] ++ lib.optionals (!useOpenCL) [
    "-DCMAKE_C_COMPILER=hipcc"
    "-DCMAKE_CXX_COMPILER=hipcc"
    "-DMIOPEN_BACKEND=HIP"
  ] ++ lib.optionals useOpenCL [
    "-DCMAKE_C_COMPILER=${clang}/bin/clang"
    "-DCMAKE_CXX_COMPILER=${clang}/bin/clang++"
    "-DMIOPEN_BACKEND=OpenCL"
  ] ++ lib.optionals buildTests [
    "-DBUILD_TESTS=ON"
    "-DMIOPEN_TEST_ALL=ON"
    "-DMIOPEN_TEST_GFX900=ON"
    "-DMIOPEN_TEST_GFX906=ON"
    "-DMIOPEN_TEST_GFX908=ON"
    "-DMIOPEN_TEST_GFX90A=ON"
    "-DMIOPEN_TEST_GFX103X=ON"
  ];

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace "enable_testing()" "" \
      --replace "MIOPEN_HIP_COMPILER MATCHES \".*clang\\\\+\\\\+$\"" "true" \
      --replace "/opt/rocm/hip" "${hip}" \
      --replace "/opt/rocm/llvm" "${llvm}" \
      --replace "3 REQUIRED PATHS /opt/rocm)" "3 REQUIRED PATHS ${hip})" \
      --replace "hip REQUIRED PATHS /opt/rocm" "hip REQUIRED PATHS ${hip}" \
      --replace "rocblas REQUIRED PATHS /opt/rocm" "rocblas REQUIRED PATHS ${rocblas}" \
      --replace "miopengemm PATHS /opt/rocm" "miopengemm PATHS ${miopengemm}" \
      --replace "set(MIOPEN_TIDY_ERRORS ALL)" "" # Fix clang-tidy at some point
  '' + lib.optionalString (!buildTests) ''
    substituteInPlace CMakeLists.txt \
      --replace "add_subdirectory(test)" ""
  '' + lib.optionalString fetchKDBs ''
    cp -a ${kdbs.gfx1030_36} src/kernels/gfx1030_36.kdb
    cp -a ${kdbs.gfx900_56} src/kernels/gfx900_56.kdb
    cp -a ${kdbs.gfx900_64} src/kernels/gfx900_64.kdb
    cp -a ${kdbs.gfx906_60} src/kernels/gfx906_60.kdb
    cp -a ${kdbs.gfx906_64} src/kernels/gfx906_64.kdb
    cp -a ${kdbs.gfx90878} src/kernels/gfx90878.kdb
    cp -a ${kdbs.gfx90a68} src/kernels/gfx90a68.kdb
    cp -a ${kdbs.gfx90a6e} src/kernels/gfx90a6e.kdb
  '';

  # Unfortunately, it seems like we have to call make on these manually
  postBuild = lib.optionalString buildDocs ''
    export HOME=$(mktemp -d)
    make doc
  '' + lib.optionalString buildTests ''
    make -j$NIX_BUILD_CORES check
  '';

  postInstall = ''
    rm $out/bin/install_precompiled_kernels.sh
  '' + lib.optionalString buildTests ''
    mkdir -p $test/bin
    mv bin/test_* $test/bin
    patchelf --set-rpath ${lib.makeLibraryPath (finalAttrs.nativeBuildInputs ++ finalAttrs.buildInputs)}:$out/lib $test/bin/*
  '';

  postFixup = lib.optionalString (buildDocs && !useOpenCL) ''
    export docDir=$doc/share/doc/miopen-hip
  '' + lib.optionalString (buildDocs && useOpenCL) ''
    export docDir=$doc/share/doc/miopen-opencl
  '' + lib.optionalString buildDocs ''
    mkdir -p $docDir
    mv ../doc/html $docDir
    mv ../doc/pdf/miopen.pdf $docDir
  '';

  passthru.updateScript = writeScript "update.sh" ''
    #!/usr/bin/env nix-shell
    #!nix-shell -i bash -p curl jq common-updater-scripts
    rocmVersion="$(curl -sL "https://api.github.com/repos/ROCmSoftwarePlatform/MIOpen/releases?per_page=1" | jq '.[0].tag_name | split("-") | .[1]' --raw-output)"
    update-source-version miopen "$rocmVersion" --ignore-same-hash --version-key=rocmVersion
  '';

  meta = with lib; {
    description = "Machine intelligence library for ROCm";
    homepage = "https://github.com/ROCmSoftwarePlatform/MIOpen";
    license = with licenses; [ mit ];
    maintainers = teams.rocm.members;
    broken = finalAttrs.rocmVersion != hip.version;
    # MIOpen will produce a very large output due to KDBs fetched
    # Also possibly in the future because of KDB generation
    hydraPlatforms = [ ];
  };
})
