{...}: {
  imports = [
    ./gitConfig.nix
  ];
  home.file.".ssh/authorized_keys".text = ''
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCvNoCdCCKYPM0Uv8nkJGupnczGeLrjSQyV03aV+CO/1JpiSsp4J9Bj+W+3tjN6Dwa0s4e9QvfYXpNGMqpEZfMJWk7/bpO+uP9FMUY7Peihvwx8McFCjwxj2INqRzO4TGGHlZ5AOcgDyakIXCzmW3WYJpU8MyYgpFZw5vpXV6X9A6qfYMOV4hgNoKFOMWVkjb/7ooQS1XTRjrOX6+GRQygD3Rm/PLWtXlpkLH/o+sPQRefuwqO3CzQohW4ThiQcdp5L9DLrhuNwNd9KENUhzYoW8gmB1i2plj5fgdNMNecQZm+QBRERRzFwVAubyqtWAdVV7JyZV8tHO5FJJJasowAfLTvDCJLAmt+f5SaGx5Zpkgl/6HhmFVtH9rCARjtRk5BqlXXDtk2TWpbHv9A/TbPb69m8T4QcJoimPIXv8lsUS40+iGmPcRGVTubR3SDXEdoTq18z5AFaU9uwuumckc/ufWTlmGkI1Ng5R7mVuaTMPPv/XPt6NmDirSAS0CUnCMZr4Q1oJ/YKkpgcLO1t0fK0mX66Z9GKk0RumvEuXvGzJyezuuZZI9ERvCX4WzGv1u7d49zJJTKnk3HCdN9wa3pCG2I6AinoAWWxgbWxDwJC1URpe5ZitpGLS2JFeNX2Txvz/oJPsm++ek2mfjIoT/DnIC9f3qbtApiSAErPqj75XQ== khoa@nixsus
  '';
}
