{
  pkgs,
  lib,
  sources,
  overrides,
  ...
}:
let
  userConfig = import ../../../nixosModules/userConfig.nix {
    inherit
      lib
      pkgs
      sources
      overrides
      ;
  };
  inherit (userConfig) mkUser;
in
{
  imports = [
    (mkUser {
      username = "khoa";
      userImports = [ ./khoa ];
      authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCvNoCdCCKYPM0Uv8nkJGupnczGeLrjSQyV03aV+CO/1JpiSsp4J9Bj+W+3tjN6Dwa0s4e9QvfYXpNGMqpEZfMJWk7/bpO+uP9FMUY7Peihvwx8McFCjwxj2INqRzO4TGGHlZ5AOcgDyakIXCzmW3WYJpU8MyYgpFZw5vpXV6X9A6qfYMOV4hgNoKFOMWVkjb/7ooQS1XTRjrOX6+GRQygD3Rm/PLWtXlpkLH/o+sPQRefuwqO3CzQohW4ThiQcdp5L9DLrhuNwNd9KENUhzYoW8gmB1i2plj5fgdNMNecQZm+QBRERRzFwVAubyqtWAdVV7JyZV8tHO5FJJJasowAfLTvDCJLAmt+f5SaGx5Zpkgl/6HhmFVtH9rCARjtRk5BqlXXDtk2TWpbHv9A/TbPb69m8T4QcJoimPIXv8lsUS40+iGmPcRGVTubR3SDXEdoTq18z5AFaU9uwuumckc/ufWTlmGkI1Ng5R7mVuaTMPPv/XPt6NmDirSAS0CUnCMZr4Q1oJ/YKkpgcLO1t0fK0mX66Z9GKk0RumvEuXvGzJyezuuZZI9ERvCX4WzGv1u7d49zJJTKnk3HCdN9wa3pCG2I6AinoAWWxgbWxDwJC1URpe5ZitpGLS2JFeNX2Txvz/oJPsm++ek2mfjIoT/DnIC9f3qbtApiSAErPqj75XQ== khoa@nixsus"
      ];
    })
    (mkUser {
      username = "neferites";
      userImports = [ ./neferites ];
      authorizedKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCtKjgINmJRIBfdFZ9E4Gt/ajw0zOItYdU0VqrLCqKdAdoVZ1UEiZIm+CRj4HAIjFNG3VAr+DOx5lyafSQRVqttv9FevGMIT0rHF2TwS+OR5HegTrICKJQY7T25+9BMoJANLXOaJw0DntZGoA+taNlxgjh6hDI+ctxbYhqm58Ez7h5NrRwWGqbwgNs9KaUAwQ7kt4Uh5/BjMspxtd0wzH37wFCPyGIW2tATBne9mGe5g+MDoWvf3UIuQNvRQOKbTpYZgQmj9EaZP8PHwexcJ6TjY1lhg591E8imyg3Tm41VRgCwI8zoQameVECpA1TlMFZwQrrHskwtgboshXHhphya/Cw9CVjm8gPsBtjWCBzKpURRgQ46z6t2rC2uq9kkMMMnvr8924AumjqCQ9hdBDq8MdEF4VZjN/MkPPYCCutj38NJ5gWi5HNI/FVc1zTgA8LfYVK7t3IJPF7C37bZMCK+1shKslzyiv+W0aQ45yikrsZujGUU6yZBgJt6Dl3LkLE="
      ];
    })
    (mkUser { username = "nixos"; })
  ];
}
