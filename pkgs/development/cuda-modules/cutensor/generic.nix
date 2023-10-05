{ cudaMajorVersion
, cudaMajorMinorVersion
, backendStdenv
, lib
, libcublas
, fetchurl
, autoPatchelfHook
, autoAddOpenGLRunpathHook
, version
, hash
}:

let
  libPath = "lib/${if cudaMajorVersion == "10" then cudaMajorMinorVersion else cudaMajorVersion}";
  mostOfVersion = builtins.concatStringsSep "."
    (lib.take 3 (lib.versions.splitVersion version));
  platform = "${backendStdenv.hostPlatform.parsed.kernel.name}-${backendStdenv.hostPlatform.parsed.cpu.name}";
in

backendStdenv.mkDerivation {
  pname = "cutensor";
  inherit version;

  src = fetchurl {
    url = if lib.versionOlder mostOfVersion "1.3.3"
      then "https://developer.download.nvidia.com/compute/cutensor/${mostOfVersion}/local_installers/libcutensor-${platform}-${version}.tar.gz"
      else "https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/${platform}/libcutensor-${platform}-${version}-archive.tar.xz";
    inherit hash;
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [
    autoPatchelfHook
    autoAddOpenGLRunpathHook
  ];

  buildInputs = [
    backendStdenv.cc.cc.lib
    libcublas.lib
  ];

  installPhase = ''
    mkdir -p "$out" "$dev"
    mv include "$dev"
    mv ${libPath} "$out/lib"
  '';

  meta = with lib; {
    description = "cuTENSOR: A High-Performance CUDA Library For Tensor Primitives";
    homepage = "https://developer.nvidia.com/cutensor";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ obsidian-systems-maintenance ];
  };
}
