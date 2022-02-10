{ stdenv
, lib
, fetchurl
, dpkg
, makeWrapper
, coreutils
, file
, gawk
, ghostscript
, gnused
, pkgsi686Linux
}:

stdenv.mkDerivation rec {
  model = "mfc9460cdn";
  pname = "${model}lpr";
  version = "1.1.1-5";

  src = fetchurl {
    # https://download.brother.com/welcome/dlf006485/mfc9460cdnlpr-1.1.1-5.i386.deb 
    url = "https://download.brother.com/welcome/dlf006485/${pname}-${version}.i386.deb";
    sha256 = "c343b44b226b3c6f5df97f485767b7bf4a4984608e5c048b129955e9796f2d50";
  };

  unpackPhase = ''
    dpkg-deb -x $src $out
  '';

  nativeBuildInputs = [
    dpkg
    makeWrapper
  ];

  dontBuild = true;

  installPhase = ''
    dir=$out/usr/local/Brother/Printer/${model}

    patchelf --set-interpreter ${pkgsi686Linux.glibc.out}/lib/ld-linux.so.2 $dir/lpd/br${model}filter

    wrapProgram $dir/inf/setupPrintcapij \
      --prefix PATH : ${lib.makeBinPath [
        coreutils
      ]}

    substituteInPlace $dir/lpd/filter${model} \
      --replace "BR_CFG_PATH=" "BR_CFG_PATH=\"$dir/\" #" \
      --replace "BR_LPD_PATH=" "BR_LPD_PATH=\"$dir/\" #"

    wrapProgram $dir/lpd/filter${model} \
      --prefix PATH : ${lib.makeBinPath [
        coreutils
        file
        ghostscript
        gnused
      ]}

    substituteInPlace $dir/lpd/psconvertij2 \
      --replace '`which gs`' "${ghostscript}/bin/gs"

    wrapProgram $dir/lpd/psconvertij2 \
      --prefix PATH : ${lib.makeBinPath [
        gnused
        gawk
      ]}
  '';

  meta = with lib; {
    description = "Brother MFC-9460CDN LPR printer driver";
    homepage = "http://www.brother.com/";
    license = licenses.unfree;
    maintainers = with maintainers; [ hexa ];
    platforms = [ "i686-linux" "x86_64-linux" ];
  };
}
