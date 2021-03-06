(* Install an oasis package on AppVeyor.
   Use by adding to the AppVeyor "install" section the lines:

   - appveyor DownloadFile "https://raw.githubusercontent.com/Chris00/ocaml-appveyor/master/install_oasis_pkg.ml"
   - ocaml install_oasis_pkg.ml url_pgk1 url_pkg2 ... url_pkgN

   The last line may be repeated if needed.
*)

open Printf

let build_folder = Sys.getenv "APPVEYOR_BUILD_FOLDER"

let ocamlroot = try Sys.getenv "OCAMLROOT"
                with _ -> "C:/PROGRA~1/OCaml"

let runf fmt =
  let exec cmd =
    printf "\027[32m▸▸▸ %s\027[0m\n%!" cmd;
    let code = Sys.command cmd in
    if code <> 0 then (
      eprintf "\027[31m⚠ Command “%s” failed with code %d\027[0m\n" cmd code;
      exit code
    ) in
  ksprintf exec fmt

let mk_temp_dir () =
  let name = Filename.temp_file "oasis" "" in
  Sys.remove name;
  ignore(Sys.command ("mkdir " ^ name));
  name

let install pkg_url =
  let fname = Filename.basename pkg_url in
  printf "\027[36m-=-=- Installing %s -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\
          \027[0m\n" fname;
  (* Work in an empty directory so the tarball expansion is the only
     content. *)
  Sys.chdir (mk_temp_dir());
  (* TODO: allow using Git sources. *)
  runf "appveyor DownloadFile \"%s\" -FileName \"../%s\"" pkg_url fname;
  runf "tar xvf \"../%s\"" fname;
  (match Sys.readdir "." with
   | [| |] -> eprintf "Extracting %s did not produce any file." fname;
              exit 1
   | [| d |] when Sys.is_directory d -> Sys.chdir d
   | _ -> ());
  runf "ocaml setup.ml -configure --prefix %s" (Filename.quote ocamlroot);
  runf "ocaml setup.ml -build";
  runf "ocaml setup.ml -install";
  printf "\027[34m-=-=- Done installing %s -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\
          \027[0m\n" fname


let () =
  for i = 1 to Array.length Sys.argv - 1 do
    install Sys.argv.(i)
  done
