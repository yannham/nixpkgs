{ options, types, ... }:
{
  options.cudnn.releases = options.mkOption
    {
      description = "A collection of cudnn packages targeting different platforms";
      type =
        # Additional options to the base package type that are specific to
        # cudnn.
        let cudnnPackageExtension = {
          options.url = options.mkOption {
            description = "The URL to download the tarball from";
            type = types.str;
          };
        };
        in
        let extendedPackageType = types.submoduleWith {
          modules = [
            config.generic.releases
            cudnnPackageExtension
          ];
          shorthandOnlyDefinesConfig = true;
        };
        in
        types.attrsOf (types.listOf extendedPackageType);
    };
}
