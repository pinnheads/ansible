#!/usr/bin/env bash
# Scenario tests for local.yml. Each scenario gets a fresh container.
#
#   ./tests/run.sh          all scenarios
#   ./tests/run.sh 3 5      only those scenarios
set -uo pipefail

REPO=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
IMAGE=ansible-test

# Repo is mounted read-only: the playbook only reads from it, and this keeps a
# test run from touching the working tree.
in_container() {
    docker run --rm \
        -v "$REPO:/home/utsav/ansible:ro" \
        -w /home/utsav/ansible \
        "$IMAGE" bash -c "set -eo pipefail; $1"
}

# 1 — clean machine, full run
scenario_1_fresh() {
    in_container '
        play --tags dev
        ansible-playbook tests/verify.yml
    '
}

# 2 — re-running must not report changes, across the whole playbook.
scenario_2_idempotent() {
    in_container '
        play --tags dev >/dev/null
        play --tags dev | tee /tmp/second
        changed=$(sed -n "s/.*localhost.*changed=\([0-9]*\).*/\1/p" /tmp/second)
        [ "$changed" = 0 ] || { echo "second run reported changed=$changed"; exit 1; }
    '
}

# 3 — ~/.dev already exists but is not a git repo
scenario_3_dev_folder_present() {
    in_container '
        mkdir -p ~/.dev && echo junk > ~/.dev/junk.txt
        play --tags dev-dotfiles
        test -d ~/.dev/.git || { echo "~/.dev was not replaced by a clone"; exit 1; }
        test ! -e ~/.dev/junk.txt || { echo "stale junk.txt survived"; exit 1; }
    '
}

# 4 — ~/.dev is a git repo but sitting on a stale commit
scenario_4_dev_stale() {
    in_container '
        git clone -q /srv/repos/.dev.git ~/.dev
        git -C ~/.dev reset -q --hard HEAD~1
        play --tags dev-dotfiles
        local_head=$(git -C ~/.dev rev-parse HEAD)
        remote_head=$(git -C /srv/repos/.dev.git rev-parse main)
        [ "$local_head" = "$remote_head" ] || { echo "~/.dev not fast-forwarded"; exit 1; }
    '
}

# 5 — a real ~/.zshrc is already in place where stow wants to symlink. Runs
# twice: the backup used to survive run 1 and get clobbered by run 2, when the
# oh-my-zsh installer moved the stowed symlink over it.
scenario_5_dotfiles_present() {
    in_container '
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

# 6 — ~/.ssh already exists with wrong permissions
scenario_6_ssh_perms() {
    in_container '
        mkdir -m 0777 ~/.ssh && install -m 0644 /dev/null ~/.ssh/id_rsa
        play --tags ssh
        [ "$(stat -c %a ~/.ssh)" = 700 ] || { echo ".ssh dir mode not fixed"; exit 1; }
        [ "$(stat -c %a ~/.ssh/id_rsa)" = 600 ] || { echo "id_rsa mode not fixed"; exit 1; }
    '
}

ALL=(scenario_1_fresh scenario_2_idempotent scenario_3_dev_folder_present
     scenario_4_dev_stale scenario_5_dotfiles_present scenario_6_ssh_perms)

echo "==> building $IMAGE"
docker build -q -f "$REPO/tests/Dockerfile" -t "$IMAGE" "$REPO" || exit 1

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
