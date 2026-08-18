#!/bin/bash
# Builds fake bare repos that stand in for the private github repos the
# playbook clones. Paired with the url.insteadOf rewrite in the Dockerfile.
set -euo pipefail

REPOS=/srv/repos
mkdir -p "$REPOS"
work=$(mktemp -d)

# .dev — the stow-based dotfiles repo. Two commits so a test can check out a
# stale one and assert the playbook fast-forwards it.
mkdir -p "$work/dev/zsh" "$work/dev/nvim/.config/nvim"
cd "$work/dev"
cat > stow <<'EOF'
#!/bin/sh
exec stow -t "$HOME" zsh nvim
EOF
chmod +x stow
echo '# managed by .dev' > zsh/.zshrc
echo '-- managed by .dev' > nvim/.config/nvim/init.lua
git init -q -b main .
git add -A
git commit -qm 'initial dotfiles'
echo '# second commit' >> zsh/.zshrc
git commit -qam 'second commit'
git clone -q --bare . "$REPOS/.dev.git"

# The two project repos only need to exist and be clonable.
for name in ansible personal-website; do
    mkdir -p "$work/$name"
    cd "$work/$name"
    echo "# $name" > README.md
    git init -q -b main .
    git add -A
    git commit -qm 'initial'
    git clone -q --bare . "$REPOS/$name.git"
done

rm -rf "$work"
