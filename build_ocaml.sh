#!/bin/bash

function run {
    NAME=$1
    shift
    echo "-=-=- $NAME -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    "$@"
    CODE=$?
    if [ $CODE -ne 0 ]; then
        echo "-=-=- $NAME failed! -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
        exit $CODE
    else
        echo "-=-=- End of $NAME -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    fi
}

cd $APPVEYOR_BUILD_FOLDER

# Do not perform end-of-line conversion
echo "Clone OCaml branch $OCAMLBRANCH"
git config --global core.autocrlf false
git clone https://github.com/ocaml/ocaml.git --branch $OCAMLBRANCH \
    --depth 1 ocaml

cd ocaml

#PREFIX=$(echo "$OCAMLROOT" | sed -e "s|\\\\|/|g")
PREFIX=$(cygpath -m -s "$OCAMLROOT")

OCAMLBRANCH_MAJOR=`echo "$OCAMLBRANCH" | sed -s 's/\([0-9]\+\).*/\1/'`
OCAMLBRANCH_MINOR=`echo "$OCAMLBRANCH" | sed -s 's/[0-9]\+\.\([0-9]\+\).*/\1/'`
if [[ "$OCAMLBRANCH" != "trunk" \
	  && (($OCAMLBRANCH_MAJOR -eq 4 && $OCAMLBRANCH_MINOR -lt 3) \
		  || $OCAMLBRANCH_MAJOR -lt 4) ]]; then
    run "Apply patch to OCaml sources (quote paths)" \
	patch -p1 < $APPVEYOR_BUILD_FOLDER/ocaml.patch
fi

if [[ ($OCAMLBRANCH_MAJOR -eq 4 && $OCAMLBRANCH_MINOR -lt 8)
      || $OCAMLBRANCH_MAJOR -lt 4 ]]; then

    if [[ "$OCAMLBRANCH" != "trunk" \
	      && (($OCAMLBRANCH_MAJOR -eq 4 && $OCAMLBRANCH_MINOR -lt 5) \
		      || $OCAMLBRANCH_MAJOR -lt 4) ]]; then
	cp config/m-nt.h config/m.h
	cp config/s-nt.h config/s.h
    else
	cp config/m-nt.h byterun/caml/m.h
	cp config/s-nt.h byterun/caml/s.h
    fi

    echo "Edit config/Makefile.msvc64 to set PREFIX=$PREFIX"
    sed -e "/PREFIX=/s|=.*|=$PREFIX|" \
	-e "/^ *CFLAGS *=/s/\r\?$/ -WX\0/" \
	config/Makefile.msvc64 > config/Makefile
    run "Content of config/Makefile" cat config/Makefile

    run "make world" make -f Makefile.nt world
    run "make bootstrap" make -f Makefile.nt bootstrap
    run "make opt" make -f Makefile.nt opt
    run "make opt.opt" make -f Makefile.nt opt.opt
    run "make install" make -f Makefile.nt install
else
    run "Configure" ./configure --build=x86_64-unknown-cygwin --host=x86_64-pc-windows --prefix="$PREFIX"
    run "make world.opt" make world.opt
    run "make install" make install
fi

run "OCaml config" ocamlc -config

#run "env" env
set Path=%OCAMLROOT%\bin;%OCAMLROOT%\bin\flexdll;%Path%
export CAML_LD_LIBRARY_PATH=$PREFIX/lib/stublibs

cd $APPVEYOR_BUILD_FOLDER

if [ -n "$INSTALL_DUNE" ]; then
    cd $APPVEYOR_BUILD_FOLDER
    echo
    echo "-=-=- Install Dune -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    #git clone https://github.com/ocaml/dune.git --depth 1 --branch=master
    git clone https://github.com/Chris00/dune.git --depth 1 --branch=master
    cd dune
    ocaml bootstrap.ml
    run "boot.exe" ./boot.exe --release --display progress
    ./_boot/default/bin/main.exe install dune \
				 --build-dir _boot --prefix "$PREFIX"
    run "dune version" dune --version
    echo "-=-=- Dune installed -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
fi

if [ -n "$OCAMLFIND_VERSION" ]; then
    cd $APPVEYOR_BUILD_FOLDER

    echo
    echo "-=-=- Build ocamlfind... -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    appveyor DownloadFile "http://download.camlcity.org/download/findlib-${OCAMLFIND_VERSION}.tar.gz"
    tar xvf findlib-${OCAMLFIND_VERSION}.tar.gz
    cd findlib-${OCAMLFIND_VERSION}
    ROOT=$(cygpath -m "$PREFIX")
    #ROOT=$(cygpath -u "$ROOT")
    # Man path not protected against spaces:
    BINDIR="$ROOT/bin"
    SITELIB="$ROOT/lib/site-lib"
    MANDIR="$ROOT/man"
    CONFIG="$ROOT/etc/findlib.conf"
    echo "bindir =$BINDIR"
    echo "sitelib=$SITELIB"
    echo "mandir =$MANDIR"
    ./configure -bindir "$BINDIR" -sitelib "$SITELIB" -mandir "$MANDIR" \
                -config "$CONFIG"
    run "Makefile.config" cat Makefile.config
    run "Build ocamlfind (byte)" make all
    run "Build ocamlfind (native)" make opt
    run "Install ocamlfind" make install
    # Small test:
    run "Content of $CONFIG" cat "$CONFIG"
    run "ocamlfind printconf" ocamlfind printconf

    echo "-=-=- ocamlfind installed -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
fi

if [ -n "$INSTALL_OPAM" ]; then
    cd $APPVEYOR_BUILD_FOLDER
    echo
    echo "-=-=- Install OPAM -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    git clone https://github.com/ocaml/opam.git --depth 1
    #git clone https://github.com/Chris00/opam.git --depth 1
    cd opam
    chmod +x shell/msvs-detect
    run "Configure OPAM with --prefix=$PREFIX" \
        ./configure --prefix="$PREFIX"

    export DUNE_ARGS=--promote-install-files
    run "Build external libraries" make lib-ext
    #ls -lR
    run "Build OPAM" make

    run "Install OPAM" make install
    run "OPAM init" opam init -y -a --bare
    run "OPAM config" opam config env
    # Install by hand, the above installation procedure fails on
    # Cygwin/Mingw
    # cp src/opam "$PREFIX/bin/opam.exe"
    # cp src/opam-admin "$PREFIX/bin/opam-admin.exe"
    # cp src/opam-admin.top "$PREFIX/bin/opam-admin-top.exe"
    # cp src/opam-installer "$PREFIX/bin/opam-installer.exe"
    run "OPAM list" opam list -i
    run "Switch to 4.07.1" opam switch create 4.07.1
    if [ -z "$OCAMLFIND_VERSION" ]; then
	opam install -y -v ocamlfind
    fi
    if [ -z "$INSTALL_DUNE" ]; then
	opam install -y -v dune
	dune --version
    fi
    if [ -z "$INSTALL_OASIS" ]; then
	run "OPAM install oasis" opam install oasis
    fi
fi

if [ -n "$INSTALL_OCAMLBUILD" ]; then
    cd $APPVEYOR_BUILD_FOLDER
    echo
    echo "-=-=- Install ocamlbuild -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    # wget https://github.com/ocaml/ocamlbuild/archive/0.11.0.tar.gz
    # tar xf 0.11.0.tar.gz
    # cd ocamlbuild-0.11.0
    # See https://github.com/ocaml/ocamlbuild/issues/261
    git clone https://github.com/ocaml/ocamlbuild.git --depth 1
    cd ocamlbuild
    make configure
    make
    # https://github.com/ocaml/ocamlbuild/issues/261
    run "Install ocamlbuild" make findlib-install
    cd ..
    run "ocamlbuild -where" ocamlbuild -where
fi

if [ -n "$INSTALL_OASIS" -a -n "$INSTALL_OCAMLBUILD" ]; then
    echo
    echo "-=-=- Install Camlp4 -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    wget https://github.com/ocaml/camlp4/archive/4.05+2.tar.gz
    tar xf 4.05+2.tar.gz
    cd camlp4-4.05-2
    ./configure --bindir="$PREFIX/bin" --libdir="$PREFIX/lib/camlp4"
    make all
    make install
    cd ..

    echo "-=-=- Install OASIS deps -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    ocaml $APPVEYOR_BUILD_FOLDER/install_oasis_pkg.ml \
	  https://forge.ocamlcore.org/frs/download.php/1702/ocamlmod-0.0.9.tar.gz \
	  https://ocaml.janestreet.com/ocaml-core/113.00/files/type_conv-113.00.02.tar.gz \
	  https://forge.ocamlcore.org/frs/download.php/1310/ocaml-data-notation-0.0.11.tar.gz \
	  http://forge.ocamlcore.org/frs/download.php/379/ocamlify-0.0.1.tar.gz

    echo "-=-=- Install OASIS deps -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    git clone https://github.com/ocaml/oasis.git
    cd oasis
    ocaml setup.ml -configure --disable-tests --prefix "$PREFIX"
    ocaml setup.ml -build
    ocaml setup.ml -install

    echo "-=-=- OASIS installed -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
fi
