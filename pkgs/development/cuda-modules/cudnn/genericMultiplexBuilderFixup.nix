{
  final,
  mkVersionedPackageName,
  cudaVersion,
  hostPlatform,
  lib,
  package,
  requireFile,
}: drv: let
  inherit (lib) lists maintainers strings;
in
  drv.overrideAttrs (finalAttrs: prevAttrs: {
    outputs =
      prevAttrs.outputs
      ++ [
        "lib"
        "static"
        "dev"
      ];

    buildInputs =
      prevAttrs.buildInputs
      ++ lists.optionals finalAttrs.passthru.useCudatoolkitRunfile [
        final.cudatoolkit
      ]
      ++ lists.optionals (!finalAttrs.passthru.useCudatoolkitRunfile) [
        final.libcublas.lib
      ];

    # Tell autoPatchelf about runtime dependencies.
    # NOTE: Versions from CUDA releases have four components.
    postFixup = strings.optionalString (strings.versionAtLeast finalAttrs.version "8.0.5.0") ''
      patchelf $lib/lib/libcudnn.so --add-needed libcudnn_cnn_infer.so
      patchelf $lib/lib/libcudnn_ops_infer.so --add-needed libcublas.so --add-needed libcublasLt.so
    '';

    passthru.useCudatoolkitRunfile = strings.versionOlder cudaVersion "11.3.999";

    meta =
      prevAttrs.meta
      // {
        description = "NVIDIA CUDA Deep Neural Network library (cuDNN)";
        homepage = "https://developer.nvidia.com/cudnn";
        maintainers = prevAttrs.meta.maintainers ++ (with maintainers; [mdaiter samuela connorbaker]);
      };
  })
