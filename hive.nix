let
  sources = import ./npins;
  pkgs = import sources.nixpkgs {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = true;
    };
  };
  createConfiguration = parent: {
    networking.hostName = parent.hostName;
    deployment = {
      buildOnTarget = true;
      # Allow local deployment with `colmena apply-local`
      allowLocalDeployment = true;
      targetUser = builtins.getEnv "USER";
      targetHost = parent.host;
      inherit (parent) tags;
    };
    imports = [ ./profiles/${parent.hostName}/configuration.nix ];
  };
in
{
  meta = {
    nixpkgs = pkgs;
  };
  gojo = createConfiguration {
    hostName = "gojo";
    host = "10.207.7.2";
    tags = [
      "didactiklabs"
      "worker"
    ];
  };
  ippo = createConfiguration {
    hostName = "ippo";
    host = "1.1.1.1";
    tags = [
      "bealv"
      "worker"
    ];
  };
  megumin = createConfiguration {
    hostName = "megumin";
    host = "10.0.1.72";
    tags = [
      "bealv"
      "worker"
    ];
  };
  vi = createConfiguration {
    hostName = "vi";
    host = "10.0.1.70";
    tags = [
      "bealv"
      "worker"
    ];
  };
  frieren = createConfiguration {
    hostName = "frieren";
    host = "10.254.0.5";
    tags = [
      "didactiklabs"
      "cp"
    ];
  };
}
