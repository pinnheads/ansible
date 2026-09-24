#!/usr/bin/env bash
# macOS counterpart of tests/run.sh. There is no macOS docker image, so the
# scenarios run natively, each against a throwaway $HOME:
#   - every path the playbook writes is derived from $HOME, so the real home
#     directory is never touched
#   - ssh/ssh-keyscan are shimmed on PATH so the private github URLs resolve to
#     local bare repos (tests/fixtures/fake-ssh.sh), and a throwaway key
#     replaces the vault-encrypted one
#   - package installs are not run for real (they would change the machine);
#     scenario 0 dry-runs them with --check instead, and the rest skip them, so
#     the tools must already be installed: `ansible-playbook local.yml --tags dev-tools`
#
#   ./tests/run-macos.sh          all scenarios
#   ./tests/run-macos.sh 3 5      only those scenarios
set -uo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)

[ "$(uname -s)" = Darwin ] || { echo "macOS only; use tests/run.sh on Linux"; exit 1; }
for bin in brew ansible-playbook stow zsh; do
    command -v "$bin" >/dev/null || {
        echo "missing '$bin'; run: ansible-playbook local.yml --tags dev-tools"; exit 1; }
done

# pwd -P: macOS temp dirs live under /var, a symlink to /private/var, and
# verify.yml compares $HOME against resolved symlink targets.
ROOT=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$ROOT"' EXIT
SHIM=$ROOT/bin

export FAKE_REPOS=$ROOT/repos
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com

echo "==> building fixtures in $ROOT"
mkdir -p "$SHIM"
ln -s "$REPO/tests/fixtures/fake-ssh.sh" "$SHIM/ssh"
printf '%s\n' '#!/bin/sh' \
    'echo "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKE"' \
    > "$SHIM/ssh-keyscan"
# Every scenario runs this instead of ansible-playbook directly.
printf '%s\n' '#!/bin/sh' \
    "exec ansible-playbook local.yml -e source_key=$ROOT/testkey --skip-tags pkg-update,dev-tools \"\$@\"" \
    > "$SHIM/play"
chmod 755 "$SHIM/ssh-keyscan" "$SHIM/play"
ssh-keygen -q -t ed25519 -N "" -C test -f "$ROOT/testkey" || exit 1
HOME=$ROOT "$REPO/tests/fixtures/make-repos.sh" || exit 1

# Runs a scenario script with a fresh $HOME. ZSH/ZSH_CUSTOM are dropped because
# the oh-my-zsh installer would otherwise install into the real ~/.oh-my-zsh.
in_sandbox() {
    local home
    home=$(mktemp -d "$ROOT/home.XXXX")
    (
        cd "$REPO" || exit 1
        unset ZSH ZSH_CUSTOM
        HOME=$home PATH="$SHIM:$PATH" bash -c "set -eo pipefail; $1"
    )
}

# 0 — the macOS package tasks resolve and would succeed (dry run only)
scenario_0_packages_check() {
    in_sandbox '
        ansible-playbook local.yml --tags dev-tools,pkg-update --check
    '
}

# 1 — clean home, full run
scenario_1_fresh() {
    in_sandbox '
        play --tags dev
        ansible-playbook tests/verify.yml
    '
}

# 2 — re-running must not report changes, across the whole playbook.
scenario_2_idempotent() {
    in_sandbox '
        play --tags dev >/dev/null
        play --tags dev | tee "$HOME/second"
        changed=$(sed -n "s/.*localhost.*changed=\([0-9]*\).*/\1/p" "$HOME/second")
        [ "$changed" = 0 ] || { echo "second run reported changed=$changed"; exit 1; }
    '
}

# 3 — ~/.dev already exists but is not a git repo
scenario_3_dev_folder_present() {
    in_sandbox '
        mkdir -p ~/.dev && echo junk > ~/.dev/junk.txt
        play --tags dev-dotfiles
        test -d ~/.dev/.git || { echo "~/.dev was not replaced by a clone"; exit 1; }
        test ! -e ~/.dev/junk.txt || { echo "stale junk.txt survived"; exit 1; }
    '
}

# 4 — ~/.dev is a git repo but sitting on a stale commit
scenario_4_dev_stale() {
    in_sandbox '
        git clone -q "$FAKE_REPOS/.dev.git" ~/.dev
        git -C ~/.dev reset -q --hard HEAD~1
        play --tags dev-dotfiles
        local_head=$(git -C ~/.dev rev-parse HEAD)
        remote_head=$(git -C "$FAKE_REPOS/.dev.git" rev-parse main)
        [ "$local_head" = "$remote_head" ] || { echo "~/.dev not fast-forwarded"; exit 1; }
    '
}

# 5 — a real ~/.zshrc is already in place where stow wants to symlink; run
# twice so the backup has a chance to get clobbered.
scenario_5_dotfiles_present() {
    in_sandbox '
        echo "# my own zshrc" > ~/.zshrc
        play --tags dev
        play --tags dev
        test -L ~/.zshrc || { echo ".zshrc is not a stow symlink"; exit 1; }
        grep -q "my own zshrc" ~/.zshrc.bak || {
            echo "the original .zshrc was lost; .zshrc.bak holds: $(head -1 ~/.zshrc.bak 2>&1)"; exit 1; }
        test ! -e ~/.zshrc.pre-oh-my-zsh || {
            echo "oh-my-zsh installer touched .zshrc despite --keep-zshrc"; exit 1; }
        ansible-playbook tests/verify.yml
    '
}

# 6 — ~/.ssh already exists with wrong permissions (BSD stat: -f %Lp)
scenario_6_ssh_perms() {
    in_sandbox '
        mkdir -m 0777 ~/.ssh && install -m 0644 /dev/null ~/.ssh/id_rsa
        play --tags ssh
        [ "$(stat -f %Lp ~/.ssh)" = 700 ] || { echo ".ssh dir mode not fixed"; exit 1; }
        [ "$(stat -f %Lp ~/.ssh/id_rsa)" = 600 ] || { echo "id_rsa mode not fixed"; exit 1; }
    '
}

ALL=(scenario_0_packages_check scenario_1_fresh scenario_2_idempotent
     scenario_3_dev_folder_present scenario_4_dev_stale
     scenario_5_dotfiles_present scenario_6_ssh_perms)

selected=()
if [ $# -gt 0 ]; then
    for n in "$@"; do
        for s in "${ALL[@]}"; do [[ $s == scenario_${n}_* ]] && selected+=("$s"); done
    done
else
    selected=("${ALL[@]}")
fi

failed=0
for s in "${selected[@]}"; do
    echo "==> $s"
    if out=$("$s" 2>&1); then
        echo "PASS $s"
    else
        echo "FAIL $s"
        echo "$out" | tail -40 | sed 's/^/    /'
        failed=1
    fi
done
exit $failed
