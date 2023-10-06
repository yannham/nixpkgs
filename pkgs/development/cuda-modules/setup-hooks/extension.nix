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
  }:
    makeSetupHook {
      name = "auto-add-opengl-runpath-hook";
      propagatedBuildInputs = [
        addOpenGLRunpath
      ];
    }
    ./auto-add-opengl-runpath-hook.sh) {};
}
