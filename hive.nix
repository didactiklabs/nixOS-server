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
  frieren = createConfiguration {
    hostName = "frieren";
    host = "10.254.0.5";
    tags = [
      "didactiklabs"
      "cp"
    ];
  };
  isaac = createConfiguration {
    hostName = "isaac";
    host = "isaac";
    tags = [
      "didactiklabs"
      "github-runner"
    ];
  };
  ippo = createConfiguration {
    hostName = "ippo";
    host = "ippo";
    tags = [
      "bealv"
      "worker"
    ];
  };
  megumin = createConfiguration {
    hostName = "megumin";
    host = "megumin";
    tags = [
      "bealv"
      "worker"
    ];
  };
  vi = createConfiguration {
    hostName = "vi";
    host = "vi";
    tags = [
      "bealv"
      "worker"
    ];
  };
}
