args@{ ... }:
let
  base = import ../../base.nix (args // { inherit hostname; });
  hostname = "generic";
in
base
