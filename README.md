# My Dotfiles

Personal configuration files and automated bootstrap for my development environment.

## Bootstrap (fresh Debian/Ubuntu install)

```bash
curl -fsSL https://raw.githubusercontent.com/LionelPinheiroDuarte/dotfiles/main/ansible/bootstrap.sh | bash
```

Installs Ansible, clones this repo, and runs the playbook — one command to a full setup.

## Test with Docker

```bash
git clone https://github.com/LionelPinheiroDuarte/dotfiles.git
cd dotfiles
docker build -t dotfiles-test -f ansible/Dockerfile .
docker run --rm dotfiles-test
```

## What's inside

- **Bash** — aliases, environment, completions
- **Vim** — lightweight config with vim-plug
- **Tmux** — Ctrl+A prefix, vi-mode, custom status bar
- **Git** — global config and aliases
- **Emacs** — literate config via `config.org`
- **Ansible** — idempotent playbook covering base tools, dev stack (Go, Node, Python, gh) and DevOps tools (Docker, kubectl, Terraform, AWS CLI)

## Credits

Thanks to [rwxrob](https://github.com/rwxrob/dot) for the bash, vim, and tmux foundations.
