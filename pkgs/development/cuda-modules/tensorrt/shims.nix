# Shims to mimic the shape of ./modules/generic/manifests/{feature,redistrib}/release.nix
{package, redistArch}: {
  featureRelease.${redistArch}.outputs = {
    hasBin = true;
    hasLib = true;
    hasStatic = true;
    hasDev = true;
    hasSample = true;
    hasPython = true;
  };
  redistribRelease = {
    name = "TensorRT: a high-performance deep learning interface";
    inherit (package) version;
  };
}