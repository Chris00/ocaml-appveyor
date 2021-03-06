[![Build status](https://ci.appveyor.com/api/projects/status/hexo6yrftl8cb0og?svg=true)](https://ci.appveyor.com/project/Chris00/ocaml-appveyor)

Use native Windows OCaml on AppVeyor
====================================

The scripts in this repository compile the *MSVC* Windows version of
OCaml and make the result available as an artifac (which is then made
available in the [releases](https://github.com/Chris00/ocaml-appveyor/releases)
tab of this repository).  While OCaml needs Cygwin to compile,
using the tarball only requires standard Windows tools.
The `.zip` file also contains:
- [`flexdll`](https://github.com/alainfrisch/flexdll);
- [`dune`](https://github.com/ocaml/dune/), starting with
  OCaml 4.05, because it is fast an Windows compatible (recommended
  for new projects);
- [`ocamlfind`](http://projects.camlcity.org/projects/findlib.html)
  because it requires Unix tools to be compiled (but can be used from the
  Windows console).

To use it to set up [AppVeyor](http://www.appveyor.com/) for your
OCaml project, put in `appveyor.yml`:

```
install:
  - appveyor DownloadFile "https://raw.githubusercontent.com/Chris00/ocaml-appveyor/master/install_ocaml.cmd" -FileName "C:\install_ocaml.cmd"
  - C:\install_ocaml.cmd
```

You can choose which OCaml version is installed by setting the
environment variable `OCAML_BRANCH`:

```
environment:
  OCAML_BRANCH: 4.08
```

Possible values are `4.02`, `4.03`, `4.05`, `4.06`, and `4.08` (the default).
You can of course test simultaneously for several of them,
see e.g.  [this `appveyor.yml`
file](https://github.com/Chris00/root1d/blob/master/appveyor.yml).

OCaml will be installed in the directory `%OCAMLROOT%` (and the
binaries will be in the path).  You can then use it to compile your
OCaml project.

Compile with dune
-----------------

To compile your project with `dune` (available for `OCAML_BRANCH`
≥ 4.08), you can adapt the following recipe:

```
build_script:
  - cd "%APPVEYOR_BUILD_FOLDER%"
  - dune subst
  - dune build -p name
```

where `name` is replaced with the name of your package.


Install packages using oasis
----------------------------

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

