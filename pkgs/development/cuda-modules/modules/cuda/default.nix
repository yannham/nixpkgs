{options, ...}: {
  imports = [
    ../generic/manifests
  ];
  options.cuda.manifests = options.generic.manifests;
}
