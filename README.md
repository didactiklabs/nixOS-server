# Installation

### Warning !!! Only work on Legacy boot installation.

On the targeted NixOS host, run `install.sh` with following arguments:

```bash
Usage: install.sh [--hostname <HOSTNAME>] [--repo <REPO_URL>] [--branch <BRANCH>] [--help]

This script installs and configures a NixOS server.

Options:
  --hostname <HOSTNAME>    The desired hostname.
  --repo <REPO_URL>        Git repository URL to clone.
  --branch <BRANCH>        Git branch name to use.
  --help                   Display this help message and exit.

Example:
  install.sh --hostname myhost --repo https://github.com/didactiklabs/nixOS-server.git --branch main
```

Require `git` to be installed on the machine.

Profile system works similarly to https://github.com/didactiklabs/nixbook.
