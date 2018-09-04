{ stdenv, fetchurl, gtk2-x11 , pkgconfig , python27 , gfortran , lesstif
, cfitsio , getopt , perl , groff , which
}:

let
  python27Env = python27.withPackages(ps: with ps; [ numpy ]);
in

stdenv.mkDerivation rec {
  srcVersion = "aug18a";
  version = "20180801_a";
  name = "gildas-${version}";

  src = fetchurl {
    url = "http://www.iram.fr/~gildas/dist/gildas-src-${srcVersion}.tar.gz";
    sha256 = "0mg3wijrj8x1p912vkgrhxbypjx7aj9b1492yxvq2y3fxban6bj1";
  };

  enableParallelBuilding = true;

  nativeBuildInputs = [ pkgconfig groff perl getopt gfortran which ];

  buildInputs = [ gtk2-x11 lesstif cfitsio python27Env ];

  patches = [ ./wrapper.patch ./return-error-code.patch ./clang.patch ./aarch64.patch ./gag-font-bin-rule.patch ];

  configurePhase=''
    substituteInPlace admin/wrapper.sh --replace '%%OUT%%' $out
    substituteInPlace admin/wrapper.sh --replace '%%PYTHONHOME%%' ${python27Env}
    substituteInPlace utilities/main/gag-makedepend.pl --replace '/usr/bin/perl' ${perl}/bin/perl
    source admin/gildas-env.sh -c gfortran -o openmp
    echo "gag_doc:        $out/share/doc/" >> kernel/etc/gag.dico.lcl
  '';

  postInstall=''
    mkdir -p $out/bin
    cp -a ../gildas-exe-${srcVersion}/* $out
    mv $out/$GAG_EXEC_SYSTEM $out/libexec
    cp admin/wrapper.sh $out/bin/gildas-wrapper.sh
    chmod 755 $out/bin/gildas-wrapper.sh
    for i in $out/libexec/bin/* ; do
      ln -s $out/bin/gildas-wrapper.sh $out/bin/$(basename "$i")
    done
  '';

  meta = {
    description = "Radioastronomy data analysis software";
    longDescription = ''
      GILDAS is a collection of state-of-the-art software
      oriented toward (sub-)millimeter radioastronomical
      applications (either single-dish or interferometer).
      It is daily used to reduce all data acquired with the
      IRAM 30M telescope and Plateau de Bure Interferometer
      PDBI (except VLBI observations). GILDAS is easily
      extensible. GILDAS is written in Fortran-90, with a
      few parts in C/C++ (mainly keyboard interaction,
      plotting, widgets).'';
    homepage = http://www.iram.fr/IRAMFR/GILDAS/gildas.html;
    license = stdenv.lib.licenses.free;
    maintainers = [ stdenv.lib.maintainers.bzizou stdenv.lib.maintainers.smaret ];
    platforms = stdenv.lib.platforms.all;
  };

}
