# cuda-modules

The files in this directory are added (in some way) to the `cudaPackages` package set by [cuda-packages.nix](../../top-level/cuda-packages.nix).

## Top-level files

Top-level nix files are included in the initial creation of the `cudaPackages` scope. These are typically required for the creation of the finalized `cudaPackages` scope:

- `backendStdenv`: Standard environment for CUDA packages.
- `flags`: Flags set, or consumed by, NVCC in order to build packages.
- `genericManifestBuilder`: Generic CUDA package builder.
  - Most packages are built using this builder.
- `genericMultiplexExtension`: A generic extension which invokes the `genericManifestBuilder` for each package in a list.
  - Used primarily for packages which have multiple variants available in a single instance of `cudaPackages`.
  - `cudnn` and `cutensor` both make use of this, as multiple versions of these packages exist within a single instance of `cudaPackages`.
- `gpus`: A list of supported NVIDIA GPUs.
- `nvccCompatibilities`: NVCC releases and the version range of GCC/Clang they support.

## Top-level directories

- `cuda`: CUDA redistributables!
  - Provides extension to `cudaPackages` scope.
- `cudatoolkit`: monolothic CUDA Toolkit run-file installer.
  - Provides extension to `cudaPackages` scope.
- `cudnn`: NVIDIA cuDNN library.
- `cutensor`: NVIDIA cuTENSOR library.
- `modules`: Nixpkgs modules to check the shape and content of CUDA redistributable and feature manifests.
  - These modules additionally use shims provided by some CUDA packages to allow them to re-use the `genericManifestBuilder`, even if they don't have manifest files of their own.
  - `cudnn` and `tensorrt` are examples of packages which provide such shims.
  - These modules are further described in the [Modules](#modules) section.
- `nccl`: NVIDIA NCCL library.
- `nccl-tests`: NVIDIA NCCL tests.
- `saxpy`: Example CMake project that uses CUDA.
- `setup-hooks`: Nixpkgs setup hooks for CUDA.
- `tensorrt`: NVIDIA TensorRT library.

## Modules

TODO(@connorbaker): more detail. Also describe the difference between the NVIDIA-provided redistributable manifest and our own feature manifest.

Modules as they are used in `modules` exist primarily to check the shape and content of CUDA redistributable and feature manifests. They are ultimately meant to reduce the repetitive nature of repackaging CUDA redistributables.

Building most redistributables follows a pattern of a manifest indicating which packages are available at a location, their versions, and their hashes. To avoid creating builders for each and every derivation, modules serve as a way for us to use a single `genericManifestBuilder` to build all redistributables.

### `generic`

Contains modules to check the hand-crafted nix release expressions (the likes of which are present in [cudnn/releases.nix](./cudnn/releases.nix) and [tensorrt/releases.nix](./tensorrt/releases.nix)) or redistributable/feature manifests (like those in [cuda/manifests](./cuda/manifests)).

Most packages have some variant of a release expression or a manifest. Modules for individual packages make a copy of the generic module. For example, the module for CUDA directly aliases the generic option without modifying it: [modules/cuda/default.nix](./modules/cuda/default.nix).

Alternatively, additional fields or values may need to be configured to account for the particulars of a package. For example, while the release expressions for [CUDNN](./cudnn/releases.nix) and [TensorRT](./tensorrt/releases.nix) are very close, they differ slightly in the fields they have. The [module for CUDNN](./modules/cudnn/default.nix) is able to use the generic module for release expressions, while the [module for TensorRT](./modules/tensorrt/default.nix) must add additional fields to the generic module.
