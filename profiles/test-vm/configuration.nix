args@{ ... }:
let
  base = import ../../base.nix (args // { inherit hostname; });
  hostname = "test-vm";
in
base
