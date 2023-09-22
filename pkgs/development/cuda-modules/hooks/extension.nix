final: prev:
let
  inherit (final.backendStdenv) cc;
  inherit (final.pkgs) addOpenGLRunpath makeSetupHook;
  inherit (prev.lib) attrsets;

  attrs = {
    # Internal hook, used by cudatoolkit and cuda redist packages
    # to accommodate automatic CUDAToolkit_ROOT construction
    markForCudatoolkitRootHook = {
      name = "mark-for-cudatoolkit-root-hook";
    };

    # Normally propagated by cuda_nvcc or cudatoolkit through their depsHostHostPropagated
    setupCudaHook = {
      name = "setup-cuda-hook";
      substitutions = {
        ccRoot = "${cc}";
        # Required in addition to ccRoot as otherwise bin/gcc is looked up
        # when building CMakeCUDACompilerId.cu
        ccFullPath = "${cc}/bin/${cc.targetPrefix}c++";
      };
    };

    autoAddOpenGLRunpathHook = {
      name = "auto-add-opengl-runpath-hook";
      propagatedBuildInputs = [
        addOpenGLRunpath
      ];
    };
  };

  # Use the given name to construct the setuphook.
  # The name (plus the shell extension) is expected to exist in this directory.
  hooks = attrsets.mapAttrs (_: args: makeSetupHook args (./. + "/${args.name}.sh")) attrs;
in
hooks
