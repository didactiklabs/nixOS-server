# Installation

### Warning !!! Only work on Legacy boot installation

Profile system works similarly to <https://github.com/didactiklabs/nixbook>.

#### - Easy Install and upgrades

<p align=left>

You only need to install the base NixOS iso.

Customization is done via the `profiles` directories.

Install or upgrade with a simple command:

```bash
colmena apply
```

#### - Kubernetes

To upgrade kubernetes version you must do the following:

##### Upgrade the control plane and kubelet configs

Run this with this repo to update the pkgs pinning:

```bash
npins add --name kubeadm-v1.31.1 github kubernetes kubernetes --at v1.31.1 # The naming is as important as the version pinned !!!
npins add --name kubelet-v1.31.1 github kubernetes kubernetes --at v1.31.1 # The naming is as important as the version pinned !!!
```

Then set the option in the module of your profile `kubernetes.version.kubeadm`.

Now run:

```bash
colmena apply # or merge to main to auto-apply it.
```

Then for the first controlplane:

```bash
colmena exec --on <cp0> "sudo kubeadm upgrade apply v1.31.1 -y -v=9"
```

Then for others and workers:

```bash
colmena exec --on <worker01>,<worker02> "sudo kubeadm upgrade node -v=9"
```

##### Upgrade kubelet

Then set the option in the module of your profile `kubernetes.version.kubelet`.

Now run:

```bash
colmena apply # or merge to main to auto-apply it.
```
