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
, gnugrep
, psutils
, a2ps
, pkgsi686Linux
}:

stdenv.mkDerivation rec {
  name = "mfc9460cdn";
  model = name;
  version = "1.1.1-5";

  src_lpr = fetchurl {
    # https://download.brother.com/welcome/dlf006485/mfc9460cdnlpr-1.1.1-5.i386.deb 
    url = "https://download.brother.com/welcome/dlf006485/${model}lpr-${version}.i386.deb";
    sha256 = "c343b44b226b3c6f5df97f485767b7bf4a4984608e5c048b129955e9796f2d50";
  };
  src_cupswrapper = fetchurl {
    # https://download.brother.com/welcome/dlf006487/mfc9460cdncupswrapper-1.1.1-5.i386.deb 
    url = "https://download.brother.com/welcome/dlf006487/${model}cupswrapper-${version}.i386.deb";
    sha256 = "4ce2d8c61b9833720f6959343e33175776c6643a3fc5694cfda788afe45959bf";
  };

  nativeBuildInputs = [
    dpkg
    makeWrapper
  ];

  unpackPhase = ''
    dpkg-deb -x $src_lpr $out
    dpkg-deb -x $src_cupswrapper $out
  '';

  installPhase = ''
    dir=$out/usr/local/Brother/Printer/${model};

    for f in \
      $out/usr/bin/brprintconf_mfc9460cdn \
      $dir/cupswrapper/brcupsconfpt1 \
      $dir/lpd/brmfc9460cdnfilter \
    ; do
      patchelf --set-interpreter ${pkgsi686Linux.glibc.out}/lib/ld-linux.so.2 $f
    done

    # lpr
    wrapProgram $dir/inf/setupPrintcapij \
      --prefix PATH : ${lib.makeBinPath [
        coreutils
      ]}

    substituteInPlace $dir/lpd/filter${model} \
      --replace "BR_PRT_PATH=" "BR_CFG_PATH=\"$dir/\" #" 

    wrapProgram $dir/lpd/filter${model} \
      --prefix PATH : ${lib.makeBinPath [
        coreutils
        file
        ghostscript
        gnused
        a2ps
      ]}

    substituteInPlace $dir/lpd/psconvertij2 \
      --replace '`which gs`' "${ghostscript}/bin/gs"

    wrapProgram $dir/lpd/psconvertij2 \
      --prefix PATH : ${lib.makeBinPath [
        gnused
        gawk
      ]}


    # cupswrapper
    substituteInPlace $dir/cupswrapper/cupswrapper${model} \
      --replace "mkdir -p /usr" ": # mkdir -p /usr" \
      --replace "chmod a+w /usr/local/Brother/" ": # chmod a+w /usr/local/Brother/" \
      --replace '/usr/local/Brother/''${device_model}/''${printer_model}/cupswrapper/brcupsconfpt1' "$dir/cupswrapper/brcupsconfpt1" \
      --replace '/usr/local/Brother/''${device_model}/''${printer_model}/lpd/filter''${printer_model}' "$dir/lpd/filter${model}" \
      --replace '/usr/share/ppd/br''${printer_model}.ppd' "$dir/cupswrapper/${model}.ppd" \
      --replace '/usr/share/cups/model/br''${printer_model}.ppd' "$dir/cupswrapper/${model}.ppd" \
      --replace 'nup="psnup' "nup=\"${psutils}/bin/psnup" \
      --replace '/usr/bin/psnup' "${psutils}/bin/psnup"

    mkdir -p $out/lib/cups/filter
    mkdir -p $out/share/cups/model

    ln $dir/cupswrapper/cupswrapper${model} $out/lib/cups/filter
    ln $dir/cupswrapper/${model}.ppd $out/share/cups/model

    sed -n '/!ENDOFWFILTER!/,/!ENDOFWFILTER!/p' "$dir/cupswrapper/cupswrapper${model}" \
    | sed '1 br; b; :r s/.*/printer_model=${model}; cat <<!ENDOFWFILTER!/' \
    | bash > $out/lib/cups/filter/brlpdwrapper${model}

    sed -i "/#! \/bin\/sh/a PATH=${lib.makeBinPath [ coreutils gnused gnugrep ]}:\$PATH" $out/lib/cups/filter/brlpdwrapper${model}

    substituteInPlace $out/lib/cups/filter/brlpdwrapper${model} \
      --replace "DEBUG=0" "DEBUG=10"
    chmod +x $out/lib/cups/filter/brlpdwrapper${model}

  '';


  meta = with lib; {
    description = "Brother MFC-9460CDN combined printer driver";
    homepage = "http://www.brother.com/";
    license = licenses.unfree;
    maintainers = with maintainers; [ diefans ];
    platforms = [ "i686-linux" "x86_64-linux" ];
  };

}
