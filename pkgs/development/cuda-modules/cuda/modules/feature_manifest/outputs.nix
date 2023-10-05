{lib, ...}: let
  inherit (lib) options types;

  example = {
    hasBin = true;
    hasDev = true;
    hasDoc = false;
    hasLib = false;
    hasSample = false;
    hasStatic = false;
  };
  # https://github.com/ConnorBaker/cuda-redist-find-features/blob/c841980e146f8664bbcd0ba1399e486b7910617b/cuda_redist_find_features/manifest/feature/package/package.py
in
  options.mkOption {
    description = "A set of outputs that a package can provide.";
    inherit example;
    type = types.submodule {
      options = {
        hasBin = options.mkOption {
          description = "A `bin` output requires that we have a non-empty `bin` directory containing at least one file with the executable bit set.";
          type = types.bool;
        };
        hasDev = options.mkOption {
          description = ''
            A `dev` output requires that we have at least one of the following non-empty directories:

            - `include`
            - `lib/pkgconfig`
            - `share/pkgconfig`
            - `lib/cmake`
            - `share/aclocal`
          '';
          type = types.bool;
        };
        hasDoc = options.mkOption {
          description = ''
            A `doc` output requires that we have at least one of the following non-empty directories:

            - `share/info`
            - `share/doc`
            - `share/gtk-doc`
            - `share/devhelp`
            - `share/man`
          '';
          type = types.bool;
        };
        hasLib = options.mkOption {
          description = "A `lib` output requires that we have a non-empty lib directory containing at least one shared library.";
          type = types.bool;
        };
        hasSample = options.mkOption {
          description = "A `sample` output requires that we have a non-empty `samples` directory.";
          type = types.bool;
        };
        hasStatic = options.mkOption {
          description = "A `static` output requires that we have a non-empty lib directory containing at least one static library.";
          type = types.bool;
        };
      };
    };
  }
