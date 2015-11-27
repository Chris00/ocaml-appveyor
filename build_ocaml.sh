#!/bin/bash

function run {
    NAME=$1
    shift
    echo "-=-=- $NAME -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    $@
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
git config --global core.autocrlf false
git clone https://github.com/ocaml/ocaml.git --branch $OCAMLBRANCH \
    --depth 1 ocaml

cd ocaml

run "Apply patch to OCaml sources" \
    patch -p1 < $APPVEYOR_BUILD_FOLDER/ocaml.patch

cp config/m-nt.h config/m.h
cp config/s-nt.h config/s.h
#cp config/Makefile.msvc config/Makefile
cp config/Makefile.msvc64 config/Makefile

PREFIX=$(echo "$OCAMLROOT" | sed -e "s|\\\\|/|")
echo "Edit config/Makefile so set PREFIX=$PREFIX"
cp config/Makefile config/Makefile.bak
sed -e "s|PREFIX=.*|PREFIX=$PREFIX|" config/Makefile.bak > config/Makefile
#run "Content of config/Makefile" cat config/Makefile

run "make world" make -f Makefile.nt world
run "make bootstrap" make -f Makefile.nt bootstrap
run "make opt" make -f Makefile.nt opt
run "make opt.opt" make -f Makefile.nt opt.opt
run "make install" make -f Makefile.nt install
