# Similar in function to the ./genericManifestBuilder.nix,
# but for packages which will have multiple versions within the same
# package set.
{
  # General arguments supplied by callPackage
  stdenv,
  backendStdenv,
  fetchurl,
  lib,
  lndir,
  zlib,
  autoPatchelfHook,
  autoAddOpenGLRunpathHook,
  cudaVersion,
  # Arguments specific to this package
  pname,
  package,
  platforms,
}: let
  inherit (lib) attrsets lists strings trivial versions maintainers licenses meta sourceTypes;
in
  backendStdenv.mkDerivation (finalAttrs: {
    inherit pname;
    inherit (package) version;

    # Don't force serialization to string for structured attributes, like outputToPatterns
    # and brokenConditions.
    # Avoids "set cannot be coerced to string" errors.
    __structuredAttrs = true;
    strictDeps = true;

    # Traversed in the order of the outputs speficied in outputs;
    # entries are skipped if they don't exist in outputs.
    outputs = ["out"];
    outputToPatterns = {
      bin = ["bin"];
      lib = ["lib" "lib64"];
      static = ["**/*.a"];
      sample = ["samples"];
      python = ["**/*.whl"];
    };

    # Useful for introspecting why something went wrong.
    brokenConditions = let
      cudaTooOld = strings.versionOlder cudaVersion package.minCudaVersion;
      cudaTooNew = (package.maxCudaVersion != null) && strings.versionOlder package.maxCudaVersion cudaVersion;
    in {
      "CUDA version is too old" = cudaTooOld;
      "CUDA version is too new" = cudaTooNew;
    };

    src = fetchurl {
      inherit (package) url hash;
    };

    # We do need some other phases, like configurePhase, so the multiple-output setup hook works.
    dontBuild = true;

    # Check and normalize Runpath against DT_NEEDED using autoPatchelf.
    # Prepend /run/opengl-driver/lib using addOpenGLRunpath for dlopen("libcudacuda.so")
    nativeBuildInputs = [
      autoPatchelfHook
      autoAddOpenGLRunpathHook
    ];

    # Used by autoPatchelfHook
    buildInputs = [
      # Note this libstdc++ isn't from the (possibly older) nvcc-compatible
      # stdenv, but from the (newer) stdenv that the rest of nixpkgs uses
      stdenv.cc.cc.lib
      zlib
    ];

    # doc and dev have special output handling. Other outputs need to be moved to their own
    # output.
    # Note that moveToOutput operates on all outputs:
    # https://github.com/NixOS/nixpkgs/blob/2920b6fc16a9ed5d51429e94238b28306ceda79e/pkgs/build-support/setup-hooks/multiple-outputs.sh#L105-L107
    installPhase = let
      mkMoveToOutputCommand = output: let
        template = pattern: ''moveToOutput "${pattern}" "${"$" + output}"'';
        patterns = finalAttrs.outputToPatterns.${output} or [];
      in
        strings.concatMapStringsSep "\n" template patterns;
    in
      # NOTE: It is important that we not use `moveToOutput` on the `out` output, because
      ''
        runHook preInstall
        mkdir -p "$out"
        mv * "$out"
        ${strings.concatMapStringsSep "\n" mkMoveToOutputCommand (builtins.tail finalAttrs.outputs)}
        runHook postInstall
      '';

    # The out output leverages the same functionality which backs the `symlinkJoin` function in
    # Nixpkgs:
    # https://github.com/NixOS/nixpkgs/blob/d8b2a92df48f9b08d68b0132ce7adfbdbc1fbfac/pkgs/build-support/trivial-builders/default.nix#L510
    #
    # That should allow us to emulate "fat" default outputs without having to actually create them.
    #
    # It is important that this run after the autoPatchelfHook, otherwise the symlinks in out will reference libraries in lib, creating a circular dependency.
    postPhases = ["postPatchelf"];

    # For each output, create a symlink to it in the out output.
    # NOTE: We must recreate the out output here, because the setup hook will have deleted it
    # if it was empty.
    postPatchelf = let
      # Note the double dollar sign -- we want to interpolate the variable in bash, not the string.
      mkJoinWithOutOutputCommand = output: ''${meta.getExe lndir} "${"$" + output}" "$out"'';
    in ''
      mkdir -p "$out"
      ${strings.concatMapStringsSep "\n" mkJoinWithOutOutputCommand (builtins.tail finalAttrs.outputs)}
    '';

    passthru = {
      majorVersion = versions.major finalAttrs.version;
      majorMinorVersion = versions.majorMinor finalAttrs.version;
      majorMinorPatchVersion = trivial.pipe finalAttrs.version [
        (versions.splitVersion)
        (lists.take 3)
        (strings.concatStringsSep ".")
      ];
      stdenv = backendStdenv;
    };

    # Setting propagatedBuildInputs to false will prevent outputs known to the multiple-outputs
    # from depending on `out` by default.
    # https://github.com/NixOS/nixpkgs/blob/2920b6fc16a9ed5d51429e94238b28306ceda79e/pkgs/build-support/setup-hooks/multiple-outputs.sh#L196
    # Indeed, we want to do the opposite -- fat "out" outputs that contain all the other outputs.
    propagatedBuildOutputs = false;

    # By default, if the dev output exists it just uses that.
    # However, because we disabled propagatedBuildOutputs, dev doesn't contain libraries or
    # anything of the sort. To remedy this, we set outputSpecified to true, and use
    # outputsToInstall, which tells Nix which outputs to use when the package name is used
    # unqualified (that is, without an explicit output).
    outputSpecified = true;

    meta = {
      inherit platforms;
      # Check that the cudatoolkit version satisfies our min/max constraints (both
      # inclusive). We mark the package as broken if it fails to satisfies the
      # official version constraints (as recorded in default.nix). In some cases
      # you _may_ be able to smudge version constraints, just know that you're
      # embarking into unknown and unsupported territory when doing so.
      broken = lists.any trivial.id (attrsets.attrValues finalAttrs.brokenConditions);
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      license = licenses.unfree;
      maintainers = with maintainers; [cuad-maintainers];
      # Force the use of the default, fat output by default (even though `dev` exists, which
      # causes Nix to prefer that output over the others if outputSpecified isn't set).
      outputsToInstall = ["out"];
    };
  })
