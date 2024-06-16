# Installation

On the targeted host, run `install.sh` with following arguments:

```bash
Usage: install.sh [--username <USERNAME>] [--hostname <HOSTNAME>] [--repo <REPO_URL>] [--branch <BRANCH>] [--help]

This script installs and configures a NixOS server.

Options:
  --username <USERNAME>    The desired main username.
  --hostname <HOSTNAME>    The desired hostname.
  --repo <REPO_URL>        Git repository URL to clone.
  --branch <BRANCH>        Git branch name to use.
  --help                   Display this help message and exit.

Example:
  install.sh --username myuser --hostname myhost --repo https://github.com/didactiklabs/nixOS-server.git --branch main
```

Require `git` to be installed on the machine.
