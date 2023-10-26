{
  cudaVersion,
  lib,
  numactl,
  rdma-core,
  gmp,
  addOpenGLRunpath,
  freeglut,
  libGLU,
  libglvnd,
  mesa,
}: let
  inherit (lib) lists strings;
  # cudaVersionOlder : Version -> Boolean
  cudaVersionOlder = strings.versionOlder cudaVersion;
  # cudaVersionAtLeast : Version -> Boolean
  cudaVersionAtLeast = strings.versionAtLeast cudaVersion;

  addBuildInputs = drv: buildInputs:
    drv.overrideAttrs (prevAttrs: {
      buildInputs = (prevAttrs.buildInputs or []) ++ buildInputs;
    });
in
  final: prev: {
    libcufile = prev.libcufile.overrideAttrs (prevAttrs: {
      buildInputs = (prev.buildInputs or []) ++ [final.libcublas.lib numactl rdma-core];
      # Before 12.0 libcufile depends on itself for some reason.
      autoPatchelfIgnoreMissingDeps = (prevAttrs.autoPatchelfIgnoreMissingDeps or []) ++ lists.optionals (cudaVersionOlder "12.0") ["libcufile.so.0"];
    });

    libcusolver = addBuildInputs prev.libcusolver (
      # Always depends on this
      [final.libcublas.lib]
      # Dependency from 12.0 and on
      ++ lists.optionals (cudaVersionAtLeast "12.0") [
        final.libnvjitlink.lib
      ]
      # Dependency from 12.1 and on
      ++ lists.optionals (cudaVersionAtLeast "12.1") [
        final.libcusparse.lib
      ]
    );

    libcusparse = addBuildInputs prev.libcusparse (
      lists.optionals (cudaVersionAtLeast "12.0") [
        final.libnvjitlink.lib
      ]
    );

    # TODO(@connorbaker): Why are these librares in `compat` and not `lib`? Will the be picked up
    # by the linker?
    cuda_compat = prev.cuda_compat.overrideAttrs (prevAttrs: {
      # TODO(@connorbaker): Why does this not work when concatenating with the previous patterns?
      # cuda_compat-aarch64-linux> error: auto-patchelf could not satisfy dependency libnvrm_gpu.so wanted by /nix/store/p1vgpxr2vi05hz5xq0b85p14s2crji1j-cuda_compat-12.0.32271208/compat/libcuda.so.1.1
      # cuda_compat-aarch64-linux> error: auto-patchelf could not satisfy dependency libnvrm_mem.so wanted by /nix/store/p1vgpxr2vi05hz5xq0b85p14s2crji1j-cuda_compat-12.0.32271208/compat/libcuda.so.1.1
      # cuda_compat-aarch64-linux> error: auto-patchelf could not satisfy dependency libnvdla_runtime.so wanted by /nix/store/p1vgpxr2vi05hz5xq0b85p14s2crji1j-cuda_compat-12.0.32271208/compat/libnvcudla.so
      # Works:
      autoPatchelfIgnoreMissingDeps = ["*"];
      # Does not work:
      # autoPatchelfIgnoreMissingDeps = [
      #   "libnvrm_gpu.so"
      #   "libnvrm_mem.so"
      #   "libnvdla_runtime.so"
      # ];
      # Also does not work, which is very odd.
      # autoPatchelfIgnoreMissingDeps = (prevAttrs.autoPatchelfIgnoreMissingDeps or []) ++ [
      #   "*"
      # ];
    });

    cuda_gdb = addBuildInputs prev.cuda_gdb (
      # x86_64 only needs gmp from 12.0 and on
      lists.optionals (cudaVersionAtLeast "12.0") [
        gmp
      ]
    );

    cuda_nvcc = prev.cuda_nvcc.overrideAttrs (prevAttrs: {
      # Required by cmake's enable_language(CUDA) to build a test program
      # When implementing cross-compilation support: this is
      # final.pkgs.targetPackages.cudaPackages.cuda_cudart
      env = {
        # Given the multiple-outputs each CUDA redist has, we can specify the exact components we
        # need from the package. CMake requires:
        # - the cuda_runtime.h header, which is in the dev output
        # - the dynamic library, which is in the lib output
        # - the static library, which is in the static output
        cudartInclude = "${final.cuda_cudart.dev}";
        cudartLib = "${final.cuda_cudart.lib}";
        cudartStatic = "${final.cuda_cudart.static}";
      };

      # Point NVCC at a compatible compiler

      # Desiredata: whenever a package (e.g. magma) adds cuda_nvcc to
      # nativeBuildInputs (offsets `(-1, 0)`), magma should also source the
      # setupCudaHook, i.e. we want it the hook to be propagated into the
      # same nativeBuildInputs.
      #
      # Logically, cuda_nvcc should include the hook in depsHostHostPropagated,
      # so that the final offsets for the propagated hook would be `(-1, 0) +
      # (0, 0) = (-1, 0)`.
      #
      # In practice, TargetTarget appears to work:
      # https://gist.github.com/fd80ff142cd25e64603618a3700e7f82
      depsTargetTargetPropagated =
        (prevAttrs.depsTargetTargetPropagated or [])
        ++ [
          final.setupCudaHook
        ];
    });

    cuda_nvprof = prev.cuda_nvprof.overrideAttrs (prevAttrs: {
      nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [addOpenGLRunpath];
      buildInputs = prevAttrs.buildInputs ++ [final.cuda_cupti.lib];
    });

    cuda_demo_suite = addBuildInputs prev.cuda_demo_suite [
      freeglut
      libGLU
      libglvnd
      mesa
      final.libcufft.lib
      final.libcurand.lib
    ];

    # nsight_compute = prev.nsight_compute.overrideAttrs (prevAttrs: {
    #   nativeBuildInputs =
    #     prevAttrs.nativeBuildInputs
    #     ++ (
    #       if (versionOlder prev.nsight_compute.version "2022.2.0")
    #       then [pkgs.qt5.wrapQtAppsHook]
    #       else [pkgs.qt6.wrapQtAppsHook]
    #     );
    #   buildInputs =
    #     prevAttrs.buildInputs
    #     ++ (
    #       if (versionOlder prev.nsight_compute.version "2022.2.0")
    #       then [pkgs.qt5.qtwebview]
    #       else [pkgs.qt6.qtwebview]
    #     );
    # });

    nvidia_driver = prev.nvidia_driver.overrideAttrs {
      # No need to support this package as we have drivers already
      # in linuxPackages.
      meta.broken = true;
    };
  }
