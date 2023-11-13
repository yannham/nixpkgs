final: _: {
  # Internal hook, used by cudatoolkit and cuda redist packages
  # to accommodate automatic CUDAToolkit_ROOT construction
  markForCudatoolkitRootHook = final.callPackage ({makeSetupHook}:
    makeSetupHook {
      name = "mark-for-cudatoolkit-root-hook";
    }
    ./mark-for-cudatoolkit-root-hook.sh) {};

  # Normally propagated by cuda_nvcc or cudatoolkit through their depsHostHostPropagated
  setupCudaHook = final.callPackage ({
    backendStdenv,
    makeSetupHook,
  }:
    makeSetupHook {
      name = "setup-cuda-hook";
      substitutions = {
        ccRoot = "${backendStdenv.cc}";
        # Required in addition to ccRoot as otherwise bin/gcc is looked up
        # when building CMakeCUDACompilerId.cu
        ccFullPath = "${backendStdenv.cc}/bin/${backendStdenv.cc.targetPrefix}c++";
      };
    }
    ./setup-cuda-hook.sh) {};

  autoAddOpenGLRunpathHook = final.callPackage ({
    addOpenGLRunpath,
    makeSetupHook,
    cuda_compat ? null,
  }:
    makeSetupHook {
      name = "auto-add-opengl-runpath-hook";
      propagatedBuildInputs =
        let
          # If we are on a platform supporting cuda_compat, we simply always use
          # it by default, as it allows to support a wider range of CUDA
          # executable given a fixed CUDA driver version.
          #
          # To enable cuda_compat, we tweak the `addOpenGLRunpath`, which is
          # already doing what we need (add the driver's path to the RUNPATH of
          # binaries), such that it appends both `${cuda_compat}/compat` and the
          # ordinary OpenGL driver path.
          addOpenGLRunpath' =
            addOpenGLRunpath.overrideAttrs (prevAttrs: {
              driverLink =
                (lib.optionalString (cuda_compat != null) "${cuda_compat}/compat:")
                ++ prevAttrs.driverLink;
            });
        in
        [ addOpenGLRunpath' ];
    }
    ./auto-add-opengl-runpath-hook.sh) {};
}
