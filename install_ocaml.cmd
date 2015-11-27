REM Download and install OCaml and flexlink (unless it was already done).
REM Prepare the environment variables,... to use it.

set OCAMLROOT=%PROGRAMFILES%/OCaml

set OCAMLURL=https://github.com/Chris00/ocaml-appveyor/releases/download/0.1/ocaml-4.02.zip

if not exist "%OCAMLROOT%/bin/ocaml.exe" (
  echo Downloading OCaml...
  appveyor DownloadFile "%OCAMLURL%" -FileName "%temp%/ocaml.zip"
  REM Intall 7za using Chocolatey:
  choco install 7zip.commandline
  cd "%PROGRAMFILES%"
  7za x -y "%temp%/ocaml.zip"
  del %temp%\ocaml.zip
)

call "C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\SetEnv.cmd" /x64

REM Add OCaml to the path & make sure that "link" is the MSVC one and
REM not the shell one.
set Path=%OCAMLROOT%\bin;%OCAMLROOT%\bin\flexdll;%VCPATH%;%FLPATH%;%Path%
set CAML_LD_LIBRARY_PATH=%OCAMLROOT%/lib/stublibs
