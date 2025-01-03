let
  nixpkgs = <nixpkgs>;
  pkgs = import nixpkgs { };
  sources = builtins.fromJSON (builtins.readFile ../npins/sources.json);
  kubernetesLatestVersion = sources.pins."kubernetes-latest".version;
in
pkgs.testers.runNixOSTest {
  name = "kubernetes-bootstrap";

  nodes = {
    master =
      { ... }:
      {
        imports = [
          ../nixosModules/kubernetes
          ../nixosModules/kernelSysctl.nix
          ../nixosModules/networkManager.nix
          ../tools.nix
        ];
        environment = {
          systemPackages = [
            pkgs.kubectl
            pkgs.cri-tools
            pkgs.iptables
          ];
        };
        networking.firewall.enable = false;
        virtualisation = {
          diskSize = 3000;
          memorySize = 2048;
          cores = 2;
        };
        customNixOSModules = {
          kubernetes = {
            enable = true;
            version = {
              kubeadm = kubernetesLatestVersion;
              kubelet = kubernetesLatestVersion;
            };
          };
        };
      };
    worker01 =
      { ... }:
      {
        imports = [
          ../nixosModules/kubernetes
          ../nixosModules/kernelSysctl.nix
          ../tools.nix
        ];
        networking.firewall.enable = false;
        environment = {
          systemPackages = [
            pkgs.iptables
          ];
        };
        virtualisation = {
          diskSize = 3000;
          memorySize = 2048;
          cores = 2;
        };
        customNixOSModules = {
          kubernetes = {
            enable = true;
            version = {
              kubeadm = kubernetesLatestVersion;
              kubelet = kubernetesLatestVersion;
            };
          };
        };
      };
  };

  testScript = ''
    master.succeed('kubeadm version -o json | jq -r .clientVersion.gitVersion | grep -q "^v1.32.0$"')
    master.wait_until_succeeds('kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint=master --apiserver-cert-extra-sans=master', timeout = 300)

    master.wait_until_succeeds('kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes | grep control-plane', timeout = 300)
    master.wait_until_succeeds('kubeadm token create abcdef.0123456789abcdef', timeout = 300)

    worker01.wait_until_succeeds('kubeadm join master:6443 --token abcdef.0123456789abcdef --discovery-token-unsafe-skip-ca-verification', timeout = 300)
    master.wait_until_succeeds('kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes | grep worker01', timeout = 300)
  '';
}
