{ options, types, ... }:
{
  options.tensorrt.releases = options.mkOption
    {
      description = "A collection of tensorrt packages targeting different platforms";
      type =
        # Additional options to the base package type that are specific to
        # cudnn.
        let tensorrtPackageExtension = {
          options = {
            cudnnVersion = lib.options.mkOption {
              description = "The CUDNN version supported";
              type = types.nullOr majorMinorVersion;
            };
            filename = lib.options.mkOption {
              description = "The tarball name";
              type = types.str;
            };
          };
        };
        in
        let extendedPackageType = types.submoduleWith {
          modules = [
            config.generic.releases
            tensorrtPackageExtension
          ];
          shorthandOnlyDefinesConfig = true;
        };
        in
        types.attrsOf (types.listOf extendedPackageType);
    };
}
