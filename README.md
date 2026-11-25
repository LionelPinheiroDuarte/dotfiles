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
- **Tmux** — Ctrl+A prefix, vi-mode, custom status bar, `prefix + ?` lists the shortcuts ([`x keys`](https://github.com/LionelPinheiroDuarte/toolbox/tree/main/x/commands/keys)), `prefix + N` for the journal popup ([`x notes --browse`](https://github.com/LionelPinheiroDuarte/toolbox/tree/main/x/commands/notes), from toolbox)
- **Git** — global config and aliases
- **SSH agent** — one `ssh-agent` per session on a fixed socket (`$XDG_RUNTIME_DIR/ssh-agent.socket`, a systemd user service), so user timers reach the keys without importing the shell's environment
- **Emacs** — literate config via `config.org`
- **Ansible** — idempotent playbook covering base tools, dev stack (Go, Node, Python, gh) and DevOps tools (Docker, kubectl, Terraform, AWS CLI)
- **Claude Code** — custom hooks under `.claude/hooks/`, e.g. a `feat`-commit trigger that keeps project READMEs in sync
- **Claude tools** — tmux bindings for the toolbox's [`x claude`](https://github.com/LionelPinheiroDuarte/toolbox/tree/main/x/commands/claude) popups: `x claude edits` (`prefix + e` / `prefix + E`) and `x claude projects` (`prefix + g`), whose state marks come from the Claude Code hooks in `.claude/settings.json`
- **Test runs** — `prefix + t` opens the toolbox's [`x tests`](https://github.com/LionelPinheiroDuarte/toolbox/tree/main/x/commands/tests) popup, a live timeline of the test runs. Mine go through it via shell functions in `.bashrc` (`npx`, `npm`, `uv`, `pytest`, `maestro`), Claude's via the [`track-tests`](https://github.com/LionelPinheiroDuarte/agents/tree/main/hooks/track-tests) hook in `.claude/settings.json`

## Credits

Thanks to [rwxrob](https://github.com/rwxrob/dot) for the bash, vim, and tmux foundations.
