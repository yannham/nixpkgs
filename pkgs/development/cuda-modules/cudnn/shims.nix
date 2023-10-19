# Shims to mimic the shape of ./modules/generic/manifests/{feature,redistrib}/release.nix
{package, redistArch}: {
  featureRelease.${redistArch}.outputs = {
    hasLib = true;
    hasStatic = true;
    hasDev = true;
  };
  redistribRelease = {
    name = "NVIDIA CUDA Deep Neural Network library (cuDNN)";
    inherit (package) version;
  };
}