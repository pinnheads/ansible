# Test image for the playbook. Build context is the repo root:
#   docker build -f tests/Dockerfile -t ansible-test .
#
# Differs from the root Dockerfile in three ways, all so scenarios run fast and
# without credentials:
#   1. every package from tasks/dev-tools.yml is preinstalled, so that task is a
#      no-op instead of a multi-minute pacman run per scenario
#   2. ssh and ssh-keyscan are faked so the private github URLs resolve to local
#      bare repos (see tests/fixtures/fake-ssh.sh)
#   3. a throwaway ssh key replaces the vault-encrypted one, so nothing needs
#      --ask-vault-pass

FROM archlinux:latest

ENV TERM=xterm
ENV LANG=en_US.UTF-8

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
        ansible sudo which \
        git make unzip gcc ripgrep fd fzf tree-sitter-cli lazygit nodejs lua \
        luarocks npm python-pip openssh neovim tmux ttf-jetbrains-mono stow \
        zsh curl && \
    useradd -m -G wheel -s /bin/bash utsav && \
    echo "utsav ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    yes | pacman -Scc

# Fake the ssh transport. ssh-keyscan is stubbed too: ansible's git module runs
# it for accept_hostkey, and it would otherwise reach the real github.com.
COPY tests/fixtures/fake-ssh.sh /usr/bin/ssh
RUN chmod 755 /usr/bin/ssh && \
    printf '%s\n' '#!/bin/sh' \
      'echo "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKE"' \
      > /usr/bin/ssh-keyscan && chmod 755 /usr/bin/ssh-keyscan

# Every scenario runs this instead of ansible-playbook directly.
RUN printf '%s\n' '#!/bin/sh' \
    'exec ansible-playbook local.yml -e source_key=/tmp/testkey --skip-tags pkg-update "$@"' \
    > /usr/local/bin/play && chmod 755 /usr/local/bin/play

RUN install -d -o utsav -g utsav /srv/repos
COPY --chown=utsav:utsav tests/fixtures/make-repos.sh /usr/local/bin/make-repos.sh

USER utsav
RUN git config --global user.email "test@example.com" && \
    git config --global user.name "Test" && \
    git config --global init.defaultBranch main && \
    /usr/local/bin/make-repos.sh && \
    ssh-keygen -q -t ed25519 -N "" -C test -f /tmp/testkey

WORKDIR /home/utsav/ansible
CMD ["bash"]
