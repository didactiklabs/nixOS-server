args@{ ... }:
let
  base = import ../../base.nix (args // { inherit hostname; });
  hostname = "frieren";
in
base
