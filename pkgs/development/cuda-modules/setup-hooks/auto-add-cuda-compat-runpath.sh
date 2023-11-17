# shellcheck shell=bash
# Patch all dynamically linked, ELF files with the CUDA driver (libcuda.so)
# coming from the cuda_compat package
echo "Sourcing auto-add-cuda-compat-runpath-hook"

elfHasDynamicSection() {
    patchelf --print-rpath "$1" >& /dev/null
}

autoAddCudaCompatRunpathPhase() (
  local outputPaths
  mapfile -t outputPaths < <(for o in $(getAllOutputNames); do echo "${!o}"; done)
  find "${outputPaths[@]}" -type f -executable -print0  | while IFS= read -rd "" f; do
    if isELF "$f"; then
      # patchelf returns an error on statically linked ELF files
      if elfHasDynamicSection "$f" ; then
        echo "autoAddCudaCompatRunpathHook: patching $f"
        patchelf --add-needed @libcudaPath@ "$f"
      elif (( "${NIX_DEBUG:-0}" >= 1 )) ; then
        echo "autoAddCudaCompatRunpathHook: skipping a statically-linked ELF file $f"
      fi
    fi
  done
)

postFixupHooks+=(autoAddCudaCompatRunpathPhase)
