{ lib, stdenv, fetchurl, zlib }:

stdenv.mkDerivation rec {
  name = "pngcheck-2.3.0";

  src = fetchurl {
    url = "mirror://sourceforge/png-mng/${name}.tar.gz";
    sha256 = "0pzkj1bb4kdybk6vbfq9s0wzdm5szmrgixkas3xmbpv4mhws1w3p";
  };

  hardeningDisable = [ "format" ];

  makefile = "Makefile.unx";
  makeFlags = [ "ZPATH=${zlib.static}/lib" ];

  buildInputs = [ zlib ];

  installPhase = ''
    mkdir -p $out/bin/
    cp pngcheck $out/bin/pngcheck
  '';

  meta = {
    homepage = "http://pmt.sourceforge.net/pngcrush";
    description = "Verifies the integrity of PNG, JNG and MNG files";
    license = lib.licenses.free;
    platforms = with lib.platforms; linux;
  };
}
