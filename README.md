[![Build Frieren](https://github.com/didactiklabs/nixOS-server/actions/workflows/build-frieren.yaml/badge.svg)](https://github.com/didactiklabs/nixOS-server/actions/workflows/build-frieren.yaml)
[![Build Gojo](https://github.com/didactiklabs/nixOS-server/actions/workflows/build-gojo.yaml/badge.svg)](https://github.com/didactiklabs/nixOS-server/actions/workflows/build-gojo.yaml)
[![Build megumin](https://github.com/didactiklabs/nixOS-server/actions/workflows/build-megumin.yaml/badge.svg)](https://github.com/didactiklabs/nixOS-server/actions/workflows/build-megumin.yaml)
[![Build vi](https://github.com/didactiklabs/nixOS-server/actions/workflows/build-vi.yaml/badge.svg)](https://github.com/didactiklabs/nixOS-server/actions/workflows/build-vi.yaml)
[![Build ippo](https://github.com/didactiklabs/nixOS-server/actions/workflows/build-ippo.yaml/badge.svg)](https://github.com/didactiklabs/nixOS-server/actions/workflows/build-ippo.yaml)

# Installation

### Warning !!! Only work on Legacy boot installation

Profile system works similarly to <https://github.com/didactiklabs/nixbook>.

#### - Easy Install and upgrades

<p align=left>

Build the iso with the following command:

```bash
nix-shell
buildIso
```

Then just run the iso in a fresh VM, it will auto install the generic profile.

Customization is done via the `profiles` directories, you can apply another profile later on by changing the hostname. Colmena looks for the hostname.

The hostname must match the name of the profile.

Install or upgrade with a simple command:

```bash
colmena apply
```

It is possible to test the iso in a vm by doing the following:

```bash
nix-shell
runIso
```

The whole installation will roll before your eyes.

#### - Kubernetes

To upgrade kubernetes version you must do the following:

##### Upgrade the control plane and kubelet configs

You first need to check if the requested kubernetes version is available in the npins/sources.json (it should be automagically be updated with our didactikbot).

If not run:

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
