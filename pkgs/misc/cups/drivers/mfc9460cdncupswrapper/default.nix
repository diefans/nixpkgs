{ lib
, stdenv
, fetchurl
, dpkg
, makeWrapper
, coreutils
, gnugrep
, gnused
, mfc9460cdnlpr
, pkgsi686Linux
, psutils
}:

stdenv.mkDerivation rec {
  model = "mfc9460cdn";
  pname = "${model}cupswrapper";
  version = "1.1.1-5";

  src = fetchurl {
    # https://download.brother.com/welcome/dlf006487/mfc9460cdncupswrapper-1.1.1-5.i386.deb 
    url = "https://download.brother.com/welcome/dlf006487/${pname}-${version}.i386.deb";
    sha256 = "4ce2d8c61b9833720f6959343e33175776c6643a3fc5694cfda788afe45959bf";
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
    lpr=${mfc9460cdnlpr}/usr/local/Brother/Printer/${model}
    dir=$out/usr/local/Brother/Printer/${model}

    interpreter=${pkgsi686Linux.glibc.out}/lib/ld-linux.so.2
    patchelf --set-interpreter "$interpreter" "$dir/cupswrapper/brcupsconfpt1"

    substituteInPlace $dir/cupswrapper/cupswrapper${model} \
      --replace "mkdir -p /usr" ": # mkdir -p /usr" \
      --replace "chmod a+w /usr/local/Brother/" ": # chmod a+w /usr/local/Brother/" \
      --replace '/usr/local/Brother/''${device_model}/''${printer_model}/cupswrapper/brcupsconfpt1' "$dir/cupswrapper/brcupsconfpt1" \
      --replace '/usr/local/Brother/''${device_model}/''${printer_model}/lpd/filter''${printer_model}' "$lpr/lpd/filter${model}" \
      --replace '/usr/share/ppd/br''${printer_model}.ppd' "$dir/cupswrapper/${model}.ppd" \
      --replace '/usr/share/cups/model/br''${printer_model}.ppd' "$dir/cupswrapper/${model}.ppd" \
      --replace 'nup="psnup' "nup=\"${psutils}/bin/psnup" \
      --replace '/usr/bin/psnup' "${psutils}/bin/psnup"

    mkdir -p $out/lib/cups/filter
    mkdir -p $out/share/cups/model

    ln $dir/cupswrapper/cupswrapper${model} $out/lib/cups/filter
    ln $dir/cupswrapper/${model}.ppd $out/share/cups/model

    sed -n '/!ENDOFWFILTER!/,/!ENDOFWFILTER!/p' "$dir/cupswrapper/cupswrapper${model}" | sed '1 br; b; :r s/.*/printer_model=${model}; cat <<!ENDOFWFILTER!/'  | bash > $out/lib/cups/filter/brlpdwrapper${model}
    sed -i "/#! \/bin\/sh/a PATH=${lib.makeBinPath [ coreutils gnused gnugrep ]}:\$PATH" $out/lib/cups/filter/brlpdwrapper${model}
    chmod +x $out/lib/cups/filter/brlpdwrapper${model}
    '';

  meta = with lib; {
    description = "Brother MFC-9460CDN CUPS wrapper driver";
    homepage = "http://www.brother.com/";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ hexa ];
  };
}
