args@{ ... }:
let
  base = import ../../base.nix (args // { inherit hostname; });
  hostname = "gojo";
in
base
