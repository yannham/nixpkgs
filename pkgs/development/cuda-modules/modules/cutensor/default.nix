{options, ...}: {
  imports = [
    ../generic/manifests
  ];
  options.cutensor.manifests = options.generic.manifests;
}
