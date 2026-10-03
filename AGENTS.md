# AGENTS.md

## Project Overview

This is a NixOS infrastructure-as-code repository managing a multi-node Kubernetes cluster across two networks (didactiklabs, bealv). It uses **Colmena** for deployment, **npins** for dependency pinning (not flakes), and **devenv** for the development environment.

## Repository Structure

```
.
├── base.nix              # Base configuration applied to all hosts
├── hive.nix              # Colmena cluster definition (all managed hosts)
├── default.nix           # Entry point for building ISOs and QCOW2 images
├── devenv.nix            # Development environment (build scripts, tools)
├── tools.nix             # Additional tools/packages
├── profiles/             # Per-host NixOS configurations
│   ├── frieren/          # Control plane (didactiklabs, 10.254.0.5)
│   ├── kazuma/           # Control plane (bealv)
│   ├── darkness/         # Control plane (bealv)
│   ├── megumin/          # Control plane (bealv)
│   ├── gojo/             # Worker (didactiklabs)
│   ├── ippo/             # Worker (bealv)
│   ├── vi/               # Worker (bealv)
│   ├── isaac/            # GitHub Actions runner host (didactiklabs)
│   ├── haganezuka/       # HAProxy load balancer (bealv)
│   ├── kaassopeia/       # QCOW2 cloud/KubeVirt image profile
│   └── kaasix/           # ISO installation profile
├── nixosModules/         # Custom NixOS modules
│   ├── kubernetes/       # Kubernetes setup (kubelet, kubeadm, containerd, CNI, sysctl)
│   ├── forgejo.nix       # Self-hosted Git forge
│   ├── ginx.nix          # Git-based auto-update service
│   ├── networkManager.nix
│   ├── sysctl.nix
│   ├── kernelSysctl.nix
│   ├── getRevision.nix
│   └── userConfig.nix    # mkUser helper
├── overlays/             # Nixpkgs overlays (kubernetes version selection)
├── installer/            # ISO builder with partition profiles
├── users/                # User configs (home-manager)
│   ├── didactiklabs/     # khoa, aamoyel, nixos
│   └── bealv/
├── npins/                # Pinned dependencies (sources.json)
├── tests/                # Test infrastructure
└── .github/              # CI/CD workflows
```

## Key Technologies

- **NixOS** with **Lix** (Nix implementation)
- **Colmena** for multi-host deployment
- **npins** for dependency pinning
- **Kubernetes** (v1.35.3) with **kubeadm**, **kubelet**, **containerd**
- **Cilium** (CNI)
- **HAProxy** for API server load balancing
- **Disko** for declarative disk partitioning
- **Home Manager** for user environments
- **Ginx** for git-based auto-updates
- **devenv** for development tooling

## Build & Deploy Commands

Available via `devenv shell`:

| Command           | Description                              |
| ----------------- | ---------------------------------------- |
| `build-iso`       | Build bootable NixOS installation ISO    |
| `build-qcow2`     | Build cloud VM image                     |
| `build-oci-qcow2` | Build OCI container with embedded QCOW2  |
| `run-iso`         | Build and boot ISO in QEMU               |
| `show-k8s-pins`   | List available Kubernetes version pins   |
| `add-k8s-pin`     | Add new Kubernetes version pin via npins |

Deploy with Colmena:

```sh
colmena apply --on @tag           # Deploy to hosts matching tag
colmena apply --on hostname       # Deploy to specific host
```

Hosts also pull `main` themselves through **ginx** (`nixosModules/ginx.nix`): on a new revision each host waits `customNixOSModules.ginx.applyDelay` seconds, then evaluates and switches in a transient `ginx-apply` unit (MemoryHigh 2G / MemoryMax 4G, low CPU/IO weight; nix-daemon has the same caps). Hosts of one cluster have different delays (kazuma 0 / darkness 600 / megumin 1200; frieren 0 / gojo 600 / ippo 1200 / vi 1800) so they never evaluate or switch together: on 2026-10-02 the three mgmt control planes evaluating at once (10 GB RAM, no kubelet reservation) made megumin thrash, its etcd stalled and it went NotReady for 4 min. `ginx.service` has `restartIfChanged = false`, so changes to the ginx unit itself only apply after a ginx restart or reboot. Don't merge host changes together with cluster (flux-mgmt) changes.

Kubernetes upgrades are automatic: when `version.kubeadm` changes, each host's `kubeadm-upgrade` unit (every 5 min) runs `kubeadm upgrade apply` while the API server reports another version, and the kubelet runs `version.kubelet`. For a **minor** upgrade, change `kubeadm` first on every control plane of the cluster and `kubelet` in a second PR once all API servers report the new version: a kubelet must never be newer than the API server. Check the CNI first (Cilium supports a given Kubernetes minor only from a given Cilium minor; mgmt went 1.18 → 1.20 before Kubernetes 1.36). Pins: `nixpkgs-k8s-<version>` via `add-k8s-pin` (npins 0.4.0 from the pinned nixpkgs; a newer npins rewrites the whole file format).

Kubelet reservations (`customNixOSModules.kubernetes.reserved.{system,kube,evictionHard}`, defaults 1Gi+512Mi reserved, evict below 500Mi) are written to `/etc/kubernetes/kubelet/config.d/99-config.conf`; changing them restarts the kubelet.

## CI/CD

- Self-hosted GitHub Actions runners (on `isaac`, 8 runners)
- Nix build cache at `s3.didactiklabs.io/nix-cache`
- Automated K8s version checking every 6 hours (`k8s-version-check.yaml`)
- Automated dependency updates (`npins-update.yaml`)
- Per-host and combined build workflows

## Coding Conventions

- All configuration is in **Nix** (no flakes, uses npins + Colmena)
- Each host profile lives in `profiles/<hostname>/default.nix`
- Kubernetes versions are pinned per-host in profile `default.nix` files
- Modules use NixOS module system conventions (`{ config, lib, pkgs, ... }:`)
- User configs follow home-manager patterns under `users/`

## Agent Guidelines

- When modifying host configs, check `hive.nix` to understand the host topology and tags
- Kubernetes module is split across `nixosModules/kubernetes/` - read the relevant submodule before changing
- Version pins live in `npins/sources.json` - use `npins` CLI or `add-k8s-pin` script, don't edit manually
- The overlay in `overlays/kubernetes.nix` provides `getKubernetesPackages` for version-specific k8s binaries
- Test changes against CI by checking `.github/workflows/` for the relevant build pipeline
- `base.nix` affects ALL hosts - be cautious with changes there
