# Builds a Docker image for an Arch Linux system
# Run: docker build --tag arch-image .

FROM archlinux:latest AS base
WORKDIR /usr/local/bin

# Suppress pacman prompts and speed up build
ENV TERM xterm
ENV LANG en_US.UTF-8

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git curl nano ansible sudo && \
    git config --global user.email "utsavdeep01@gmail.com" && \
    git config --global user.name "Utsav" && \
    yes | pacman -Scc

# Optional: Set a default shell (bash) and locale
SHELL ["/bin/bash", "-c"]

CMD ["bash"]

