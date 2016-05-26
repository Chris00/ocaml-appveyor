Use native Windows OCaml on AppVeyor
====================================

The scripts in this repository compile the *MSVC* Windows version of
OCaml and make the result available as an artifac (which is then made
available in the [releases](https://github.com/Chris00/ocaml-appveyor/releases)
tab of this repository).
[`flexdll`](http://alain.frisch.fr/flexdll.html) is also included in
the tarball.  While this version of OCaml needs Cygwin to compile,
using the tarball only requires standard Windows tools.

[`ocamlfind`](http://projects.camlcity.org/projects/findlib.html) is
compiled (because it also requires Unix tools) and bundled in the
OCaml tarball.

To use it to set up [AppVeyor](http://www.appveyor.com/) for your
OCaml project, put in `appveyor.yml`:

```
install:
  - appveyor DownloadFile "https://raw.githubusercontent.com/Chris00/ocaml-appveyor/master/install_ocaml.cmd" -FileName "C:\install_ocaml.cmd"
  - C:\install_ocaml.cmd
```

OCaml will then be installed in the directory `%OCAMLROOT%`.  You can
then use it to compile your OCaml project (here using
[oasis](https://ocaml.org/learn/tutorials/setting_up_with_oasis.html)):

```
build_script:
  - cd "%APPVEYOR_BUILD_FOLDER%"
  - ocaml setup.ml -configure --enable-tests --prefix "%OCAMLROOT%"
  - ocaml setup.ml -build
  - ocaml setup.ml -info -install
```

Unfortunately, [opam](http://opam.ocaml.org/) does not yet work on
native Windows.  As a transient measure, if your package depends on
other packages that use oasis, you can add the following instructions
to the `install` target of `appveyor.yml`:

```
  - appveyor DownloadFile "https://raw.githubusercontent.com/Chris00/ocaml-appveyor/master/install_oasis_pkg.ml"
  - ocaml install_oasis_pkg.ml <url-pkg1> <url-pkg2> ...
```



Related projects
----------------

- https://github.com/braibant/ocaml-windows-bootstrap
- https://protz.github.io/ocaml-installer/

