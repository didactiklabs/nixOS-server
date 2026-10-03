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

Disk: every generation's closure stays on disk until the nightly GC (`--delete-older-than 7d`), so keep host closures lean (kazuma: 6.5 GB → 4.4 GB on 2026-10-03). Users get `homeManagerModules/server.nix` (lean zsh/git) plus nixbook's `sshConfig`/`fastfetchConfig`; don't import nixbook's `zshConfig`/`gitConfig` (they bring devenv→llvm, yazi, gh extensions, difftastic). `overlays/server.nix` swaps nixbook's `fastfetch` for the minimal build (EFL/GUI deps were 1.4 GB); overlays must be listed in hive.nix (colmena's pkgs, used by home-manager) as well as base.nix/default.nix. VM profiles set `hardware.enableAllFirmware = false`. kubelet removes images unused for 7 days (`imageMaximumGCAge`). `ginx-apply` and `osupdate` evaluate with an empty Nix cache: after a GC, Lix's fetcher cache pointed at deleted eval-only sources (nixbook, nixpkgs-k8s-*) and every evaluation failed with "path '…-source' is not valid"; if that ever happens on an old generation, `sudo rm -rf /root/.cache/nix` and rerun.

KaaS worker images (`kaassopeia`, Proxmox templates used by the bealv ClusterClass variables `templateID`/`templateAltID`): build one per Kubernetes minor of the upgrade path with `build-qcow2 kaassopeia <version>` (on a host with KVM; `default.nix` takes `k8sVersion` and overrides the profile's kubeadm/kubelet). Kamaji only accepts sequential minors, so bealv 1.34.0 → 1.35.4 → 1.36.3 needs two templates; each step is one patch of the bealv `Cluster` (`spec.topology.version` + `templateID`/`templateAltID` to the new templates), after Cilium on bealv supports the target (1.35: Cilium ≥ 1.19; 1.36: ≥ 1.20, one Cilium minor at a time, see flux-mgmt AGENTS.md).

KaaS templates from CI (`.github/workflows/kaas-templates.yaml`, manual run with a version list, or on changes to `profiles/kaassopeia`): GitHub-hosted runners build `build-qcow2 kaassopeia <version>`, join the tailnet (ephemeral `tag:ci`, OPNsense subnet routes) stage the qcow2 on GHCR (`ghcr.io/didactiklabs/kaassopeia-image`, single-file OCI artifact) and run `scripts/proxmox-publish-template.sh`, which has Proxmox download it from a short-lived signed URL into `local` (import content; the API upload over the tailnet took 22 min from US runners), creates one template per Proxmox storage in `TEMPLATE_STORAGES` (default `disk_hdd disk_hddb`: Proxmox storage IDs, not the Kubernetes StorageClass names `disk-hdd`/`disk-hddb`; the ClusterClass `templateID` and `templateAltID` point at one each) with the hardware of template 997, and tags it `kaassopeia;k8s-v<version>;img-<hash>;storage-<id>`. The boot disk is `TEMPLATE_DISK_SIZE` (70G): CI grows the qcow2's virtual size before staging it (sparse, same download), because `qemu-img resize` on Proxmox's HDD storage times out; the image grows its partition and filesystem on boot, and clones inherit the size. A failed publish deletes its unfinished VM. Storages that already have a template of that image with a big enough disk are skipped; a smaller one is replaced (and superseded). A newer image for the same version on the same storage takes the `k8s-v<version>` tag and the old template there becomes `superseded-k8s-v<version>` (kept; delete old ones by hand). One-time setup:

- Proxmox (on proxmox-alv): `pvesm set local --content <existing types>,import`; `pveum role add KaaSTemplates -privs "VM.Allocate VM.Audit VM.Config.Disk VM.Config.CPU VM.Config.Memory VM.Config.Network VM.Config.HWType VM.Config.Options VM.Config.Cloudinit Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit SDN.Use"`; `pveum user add ci@pve`; `pveum aclmod / -user ci@pve -role KaaSTemplates`; `pveum user token add ci@pve kaas --privsep 0`; Proxmox downloads the staged image itself (`download-url`), which needs `pveum role modify KaaSTemplates -privs Sys.AccessNetwork --append 1` → secrets `PVE_TOKEN_ID` (`ci@pve!kaas`) / `PVE_TOKEN_SECRET`.
- Tailscale: OAuth client (scope `auth_keys`, tag `tag:ci`) → secrets `TS_OAUTH_CLIENT_ID` / `TS_OAUTH_SECRET`; ACL `tagOwners` for `tag:ci` and a grant from `tag:ci` to the Proxmox API (`:8006`) and the bealv DNS resolver (`:53`); split DNS `bealv.lan` → the OPNsense resolver (or set the `PVE_URL` variable to an IP).
- Repo variable `KAAS_TEMPLATES_ENABLED=true`.
- Repo variable `PVE_PINNED_PUBKEY`: the API certificate comes from Proxmox's own CA (`CN=proxmox-alv`, no `proxmox.bealv.lan` SAN), so the workflow pins its public key. After a certificate renewal with a new key the publish step fails closed; recompute with `echo | openssl s_client -connect proxmox.bealv.lan:8006 2>/dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl base64` and set `sha256//<that>`. Optional variables: `PVE_URL`, `PVE_NODE`, `REFERENCE_VMID`, `TEMPLATE_STORAGES`, `IMPORT_STORAGE`, `PVE_INSECURE=1` (if the API certificate isn't from the bealv CA).

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
