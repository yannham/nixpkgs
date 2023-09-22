# cuda-modules

TODO(@connorbaker): Finish genericizing cuTensor; misc.

The files in this directory are added (in some way) to the `cudaPackages` package set by [cuda-packages.nix](../../top-level/cuda-packages.nix).

## Contents

### Top-level files

Top-level nix files are included in the initial creation of the `cudaPackages` scope. These are typically required for the creation of the finalized `cudaPackages` scope:

- `backendStdenv`: Standard environment for CUDA packages.
- `gpus`: A list of supported NVIDIA GPUs.
- `flags`: Flags to build packages.
- `nvccCompatibilities`: NVCC releases and the version range of GCC/Clang they support.

### Top-level directories

- `cuda`: CUDA redistributables!
  - Provides extension to `cudaPackages` scope.
- `cudatoolkit`: monolothic CUDA Toolkit runfile installer.
  - Provides extension to `cudaPackages` scope.
- `cudnn`: NVIDIA cuDNN library.
- `cutensor`: NVIDIA cuTENSOR library.
- `hooks`: Nixpkgs hooks for CUDA.
- `nccl`: NVIDIA NCCL library.
- `nccl-tests`: NVIDIA NCCL tests.
- `saxpy`: Example CMake project that uses CUDA.
- `tensorrt`: NVIDIA TensorRT library.
