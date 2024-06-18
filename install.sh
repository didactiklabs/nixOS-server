#!/usr/bin/env bash
set -euo pipefail

print_help() {
    echo "Usage: $(basename "$0") [--username <USERNAME>] [--hostname <HOSTNAME>] [--repo <REPO_URL>] [--rev <REV>] [--help]"
    echo ""
    echo "This script installs and configures a NixOS server."
    echo ""
    echo "Options:"
    echo "  --username <USERNAME>    The desired main username."
    echo "  --hostname <HOSTNAME>    The desired hostname."
    echo "  --repo <REPO_URL>        Git repository URL to clone."
    echo "  --rev <REV>           Git rev name to use."
    echo "  --help                   Display this help message and exit."
    echo ""
    echo "Example:"
    echo "  $(basename "$0") --username myuser --hostname myhost --repo https://github.com/didactiklabs/nixOS-server.git --rev main"
}

username=
hostname=
git_repo=
rev=

# Parse command-line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
    --username)
        username="$2"
        shift 2
        ;;
    --hostname)
        hostname="$2"
        shift 2
        ;;
    --repo)
        git_repo="$2"
        shift 2
        ;;
    --rev)
        rev="$2"
        shift 2
        ;;
    --help)
        print_help
        exit 0
        ;;
    *)
        echo "Unknown parameter passed: $1"
        print_help
        exit 1
        ;;
    esac
done

# Validate if username and hostname are provided
if [[ -z "$username" || -z "$hostname" || -z "$git_repo" || -z "$rev" ]]; then
    echo "Error: Missing arguments."
    print_help
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

echo '''
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡀⠀⠀⠀⠀⠀⠀⠀⡔⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⢚⣉⣠⡽⠂⠀⠀⠀⠀⡰⢋⡼⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⢴⡆⠀⠀
⠀⠀⠀⠀⠀⢀⡤⠐⢊⣥⠶⠛⠁⢀⠄⡆⣠⠤⣤⠞⢠⠿⢥⡤⠀⠀⠠⢤⠀⠀⠀⠤⠤⠤⡄⢠⠤⠄⠤⠀⠀⠀⠒⣆⡜⣿⣄⠀⡤⢤⠖⣠⣀⠤⢒⣭⠶⠛⠃⠀⠀
⢀⣀⡠⢴⣎⣥⣴⣾⣟⡓⠒⠒⠒⠺⣄⡋⢀⡾⢃⣴⢖⣢⣞⢁⣋⣉⣹⠏⠚⠛⢛⣉⣤⡴⢞⠃⣰⠾⠟⣛⣩⢵⢶⡟⣰⠇⠘⡼⢡⡟⣀⡋⢵⡞⠋⠁⠀⠀⠀⠀⠀
⠈⠢⠄⠤⠤⠤⠤⠤⠴⠤⠴⠶⠶⢾⠟⣱⡿⢤⢿⣕⠾⣿⣿⣩⡭⢤⠞⣰⠶⢤⣀⡉⠓⢾⡍⣠⠴⠾⠛⠹⠡⣟⡁⢰⢏⣼⡇⢰⣿⢀⠟⠳⣤⣌⣦⡀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⢃⡼⠋⠛⠾⠚⠁⠀⠈⠉⠀⠀⠸⣄⠏⠀⠀⠈⠙⠓⡟⣰⠏⠀⠀⠀⠘⠾⠛⠳⠞⠉⠁⠙⠋⠙⠚⠀⠀⠀⠙⠛⢿⣷⣤⣀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣜⡵⠟⠀⠀⠀⠀⠀⠀⣼⣿⣾⣿⣽⣽⣿⣿⢏⢫⣻⡹⡽⣰⢏⣯⠍⡭⡍⣭⢩⡭⢩⡍⡏⡏⣯⡍⣍⠙⡭⢹⣄⣤⠄⢠⠉⠓⢿⣕⡄
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⣯⠃⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⣿⣿⣽⣾⣾⣟⣯⣣⣱⣾⣟⣞⣸⣇⣳⣃⣿⣛⣷⣬⠧⠳⠇⠿⢧⢿⢀⣷⢸⠧⢾⢃⠇⠀⠀⠀⠀⠁
'''
echo "Welcome to the nova NixOS server installation script choom !"
echo ""
echo "Your username is: $username"
echo "Your hostname is: $hostname"
echo ""

nixos_dir="/home/$username/Documents/nixos_install"
config_tpl="./configuration.nix.tpl"
config_file="./configuration.nix"
profile_dir="./profiles/$username-$hostname"

attempt=1
retry_count=5
retry_interval=3
while [ $attempt -le $retry_count ] || [ $success != "true" ]; do
    if [ ! -d "$nixos_dir" ]; then
        git clone "$git_repo" "$nixos_dir" || attempt=$((attempt + 1)) continue
        break
    fi
    sleep $retry_interval
    cd $nixos_dir
    git config pull.rebase true
    git config --global --add safe.directory $nixos_dir || attempt=$((attempt + 1)) continue
    git reset --hard
    chown $username $nixos_dir -R
    git tag -d $rev || echo No local tags found.
    git fetch || attempt=$((attempt + 1)) continue
    git checkout $rev
    git pull origin $rev -f || attempt=$((attempt + 1)) continue
    # Get the current HEAD commit hash
    current_commit=$(git rev-parse $rev)
    saved_commit=
    if [[ -f novaStatus.keep ]]; then
        saved_commit=$(<novaStatus.keep)
    else
        echo "novaStatus.keep file not found!"
    fi
    # Read the content of the status.keep file
    # Compare the two hashes
    if [[ "$current_commit" == "$saved_commit" ]]; then
        echo "The commit hash matches the one in novaStatus.keep."
        exit 0
    fi
    git clean -f
    chown $username $nixos_dir -R
    break
done

echo "Removing old /etc/nixos configuration link..."
rm -rf /etc/nixos || {
    echo "Failed to remove /etc/nixos"
    exit 1
}
echo "Regenerating hardware configuration files..."
nixos-generate-config --show-hardware-config >$nixos_dir/hardware-configuration.nix

echo "Configuring hostname & username..."
sed "s/%USERNAME%/$username/g" "$config_tpl" | sed "s/%HOSTNAME%/$hostname/g" >"$config_file" || {
    echo "Failed to create configuration.nix"
    exit 1
}

echo "Linking nixos directory to /etc/nixos ..."
ln -sfn "$nixos_dir" /etc/nixos || {
    echo "Failed to create symlink to /etc/nixos"
    exit 1
}

echo "Reconfiguring nixos..."
nixos-rebuild boot || {
    echo "nixos-rebuild boot failed"
    exit 1
}
nixos-rebuild switch || {
    echo "nixos-rebuild switch failed"
    exit 1
}
git rev-parse @ >./novaStatus.keep
nix-collect-garbage --delete-older-than 30d
echo '''
    ⠀⢀⣣⠏⠀⠀⠀⠀⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⠃⠀⠀⠀⣧⣀⡀
    ⠀⢼⠏⠀⠀⠀⠀⢠⡃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⣗⠀⠀⠀⣰⡟⠀⠀
    ⠀⡾⠀⢀⣀⣰⣤⣼⣷⣼⣿⣷⣮⣕⡒⠤⠀⠀⠀⠀⠀⠀⠙⣦⣤⣴⡟⠀⠀⢠
    ⢰⡇⢐⣿⠏⠉⠉⠉⠙⠙⠋⠉⠁⠀⠈⠢⣄⡉⠑⠲⠶⣶⣾⣿⣿⣿⣿⣄⣠⣿
    ⢸⡇⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠷⣶⣮⣭⣽⣿⣿⣿⣿⣿⣿⣿
    ⢸⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠹⣿⣿⣿⣿⠿⢿⠟⢁⣭
    ⢸⣿⣿⡇⣀⠠⠀⡀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣄⣀⠀⡠⠨⡙⠻⣿⣿⠏⢠⣏⠳
    ⠘⢿⣿⣿⠀⢱⢉⠿⠳⣆⠀⠀⠀⠀⠩⠋⢲⡿⠈⢙⣶⠄⠘⢆⢹⡟⠀⣿⢿⠀
    ⠀⠈⠻⣿⡇⠈⠄⢿⣤⣬⠀⠀⠀⠀⠀⢀⡈⠻⠶⢾⡟⠀⠀⡸⠀⠀⢔⠅⢚⣴
    ⣄⣴⣾⣿⣿⠀⠀⢑⠒⠋⠀⠀⠀⠀⠀⠀⠀⠉⢏⠀⠀⠀⠔⠀⠀⠀⠁⡤⢿⣿
    ⠿⢿⣿⣿⣿⣷⢴⠟⠀⠀⢀⡀⠀⠀⠀⠀⠀⠀⠙⠵⠤⠊⠀⠀⣼⣿⡏⢀⠔⠁
    ⠀⠀⠹⣿⣿⠟⢮⠀⠀⠀⠈⠉⠁⠀⠀⠀⠀⠀⠀⠁⠀⠀⣠⣾⣿⣿⡷⠉⠀⠀
    ⣆⠀⠀⢿⡇⠀⠀⢱⣤⡀⠀⠉⠛⠋⠉⠁⠀⠀⠀⢀⣴⣾⣿⣿⠟⠛⠢⡄⠀⠀
    ⠈⠀⠀⠸⣿⣆⠀⠀⢿⣿⣦⣀⠀⠀⠀⠀⣀⢤⣾⣿⣿⡿⠟⠁⠀⠀⠀⠹⡄⠀
    ⠀⠀⠀⠀⠀⠈⠀⠀⠀⠛⠛⠿⠷⠒⠒⠯⠀⠀⠶⠾⠋⠀⠀⠀⠀⠀⠀⠀⠿⠄
'''
echo "Installation Complete choom !"
