{
  stdenv,
  lib,
  ...
}:
stdenv.mkDerivation {
  name = "sources";
  src = lib.cleanSource ../.;
  installPhase = ''
    mkdir $out
    cp -r $src/. $out
  '';
}
