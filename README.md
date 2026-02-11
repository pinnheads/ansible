<div align = "center">

<h1><a href="https://github.com/pinnheads/ansible">Ansible Workstation Automation</a></h1>

<a href="https://github.com/pinnheads/ansible/blob/main/LICENSE">
<img alt="License" src="https://img.shields.io/github/license/pinnheads/ansible?style=flat&color=eee&label="> </a>

<a href="https://github.com/pinnheads/ansible/pulse">
<img alt="Last Updated" src="https://img.shields.io/github/last-commit/pinnheads/ansible?style=flat&color=e06c75&label="> </a>

<h3>Automated provisioning for Ubuntu and Arch Linux 🚀</h3>

<figure>
  <img src="images/screenshot.png" alt="Ansible in action">
</figure>

</div>

This repository contains Ansible playbooks to automate the setup of a Linux development environment. It handles everything from shell configuration (Zsh/Oh-My-Zsh) to development tools (Node/NVM, Docker) and system utilities.

## ✨ Features

-   **Multi-Distro Support:** Tailored tasks for both Arch Linux and Debian/Ubuntu.
-   **Modern Shell:** Automated Zsh setup with Oh-My-Zsh and autosuggestions.
-   **Dev Ready:** Installs NVM, Node.js, Docker, and Neovim.
-   **Fast Testing:** Includes Docker-based testing environments with volume mounting for rapid iteration.

## Setup

### ⚡ Requirements

-   Ansible >= 2.10
-   Git
-   Sudo privileges

### 🚀 Installation & Usage

1. **Clone the repo:**
   ```bash
   git clone https://github.com/pinnheads/ansible
   cd ansible
   ```

2. **Run the playbook:**
   ```bash
   ansible-playbook local.yml --ask-become-pass
   ```

3. **Test in a sandbox (Arch):**
   ```bash
   ./utils/arch/create-arch-docker.sh
   # Inside the container:
   ansible-playbook local.yml
   ```

## 🛠 Future Improvements

### 🔧 Core Enhancements
- [ ] **Cross-Distro Parity:** Port Neovim and Alacritty installation tasks to Arch Linux.
- [ ] **Idempotency Fixes:** Ensure scripts like Oh-My-Zsh and NVM installation don't attempt to re-download if already present (using `creates` or `stat`).
- [ ] **Dotfiles Management:** Better integration with `stow` and a dedicated `dotfiles/` directory structure.
- [ ] **Ansible Vault:** Secure the `.ssh/id_rsa` and `auth-codes/` using Ansible Vault instead of storing them in plain text.

### 📦 Application Additions
- [ ] **Browser Automation:** Scripts to install and configure Brave/Chrome with specific extensions.
- [ ] **Container Improvements:** Add an Ubuntu testing container with the same "fast-test" volume mounting logic as the Arch script.
- [ ] **LazyVim/AstroNvim:** Add options to choose between different Neovim distributions.

### 🧪 CI/CD & Testing
- [ ] **GitHub Actions:** Run `ansible-lint` and test the playbooks in the provided Docker containers on every push.
- [ ] **Variable Externalization:** Move user-specific strings (like git names/emails) into a `vars/main.yml` file for easier customization.

<hr>

<div align="center">

<strong>⭐ hit the star button if you found this useful ⭐</strong><br>

<a href="https://github.com/pinnheads/ansible">Source</a>
| <a href="https://twitter.com/utsavdeep01" target="_blank">Twitter </a>
| <a href="https://linkedin.com/in/utsavdeep" target="_blank">LinkedIn </a>
| <a href="https://utsavdeep.com" target="_blank">Portfolio Website </a>

</div>
