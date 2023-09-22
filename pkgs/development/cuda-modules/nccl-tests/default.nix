{ config
, cuda_cudart
, cuda_nvcc
, backendStdenv
, fetchFromGitHub
, lib
, mpiSupport ? false
, mpi
, nccl
, which
}:

backendStdenv.mkDerivation (finalAttrs: {

  pname = "nccl-tests";
  version = "2.13.6";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = finalAttrs.pname;
    rev = "v${finalAttrs.version}";
    hash = "sha256-3gSBQ0g6mnQ/MFXGflE+BqqrIUoiBgp8+fWRQOvLVkw=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cuda_nvcc
    which
  ];

  buildInputs = [
    cuda_cudart
    nccl
  ] ++ lib.optional mpiSupport mpi;

  makeFlags = [
    "CUDA_HOME=${cuda_nvcc}"
    "NCCL_HOME=${nccl}"
  ] ++ lib.optionals mpiSupport [
    "MPI=1"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    mkdir -p $out/bin
    cp -r build/* $out/bin/
  '';

  meta = with lib; {
    description = "Tests to check both the performance and the correctness of NVIDIA NCCL operations";
    homepage = "https://github.com/NVIDIA/nccl-tests";
    platforms = [ "x86_64-linux" ];
    license = licenses.bsd3;
    broken = !config.cudaSupport || (mpiSupport && mpi == null);
    maintainers = with maintainers; [ jmillerpdt ];
  };
})
