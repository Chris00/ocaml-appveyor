REM Download and install OCaml and flexlink (unless it was already done).
REM Prepare the environment variables,... to use it.
REM
REM If you are using Cygwin, install it in C:\cygwin first and then
REM execute this script.

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

set Path=%OCAMLROOT%\bin;%OCAMLROOT%\bin\flexdll;%Path%
set CAML_LD_LIBRARY_PATH=%OCAMLROOT%/lib/stublibs

set CYGWINBASH=C:\cygwin\bin\bash.exe

if exist %CYGWINBASH% (
  REM Make sure that "link" is the MSVC one and not the Cynwin one.
  echo VCPATH="`cygpath -p '%Path%'`" > C:\cygwin\tmp\msenv
  echo PATH="$VCPATH:$PATH" >> C:\cygwin\tmp\msenv
  %CYGWINBASH% -lc "tr -d '\\r' </tmp/msenv > ~/.msenv64"
  %CYGWINBASH% -lc "echo '. ~/.msenv64' >> ~/.bash_profile"
)
