{ autoAddOpenGLRunpathHook
, cmake
, cudaPackages
, cudatoolkit
, fetchFromGitHub
, fetchpatch
, freeimage
, glfw3
, lib
, pkg-config
  # Supplied by caller
, cudaVersion
, hash
}:
let
  inherit (cudaPackages) backendStdenv;
  inherit (lib) lists strings;
in
backendStdenv.mkDerivation (finalAttrs: {
  strictDeps = true;

  pname = "cuda-samples";
  version = cudaVersion;

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = finalAttrs.pname;
    rev = "v${finalAttrs.version}";
    inherit hash;
  };

  nativeBuildInputs = [
    autoAddOpenGLRunpathHook
    pkg-config
  ]
  # CMake has to run as a native, build-time dependency for libNVVM samples.
  # However, it's not the primary build tool -- that's still make.
  # As such, we disable CMake's build system.
  ++ lists.optionals (strings.versionAtLeast finalAttrs.version "12.2") [
    cmake
  ];

  dontUseCmakeConfigure = true;

  buildInputs = [
    cudatoolkit
    freeimage
    glfw3
  ];

  # See https://github.com/NVIDIA/cuda-samples/issues/75.
  patches = lib.optionals (finalAttrs.version == "11.3") [
    (fetchpatch {
      url = "https://github.com/NVIDIA/cuda-samples/commit/5c3ec60faeb7a3c4ad9372c99114d7bb922fda8d.patch";
      sha256 = "sha256-0XxdmNK9MPpHwv8+qECJTvXGlFxc+fIbta4ynYprfpU=";
    })
  ];

  enableParallelBuilding = true;

  preConfigure = ''
    export CUDA_PATH=${cudatoolkit}
  '';

  installPhase =
    let
      parsedHostPlatform = backendStdenv.hostPlatform.parsed;
      cpuName = parsedHostPlatform.cpu.name;
      kernelName = parsedHostPlatform.kernel.name;
    in
    ''
      runHook preInstall

      install -Dm755 -t $out/bin bin/${cpuName}/${kernelName}/release/*

      runHook postInstall
    '';

  meta = {
    description = "Samples for CUDA Developers which demonstrates features in CUDA Toolkit";
    # CUDA itself is proprietary, but these sample apps are not.
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ obsidian-systems-maintenance ] ++ lib.teams.cuda.members;
  };
})
