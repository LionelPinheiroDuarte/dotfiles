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
- **Claude Code** — custom hooks under `.claude/hooks/`, e.g. a `feat`-commit trigger that keeps project READMEs in sync
- **`claude-edits`** — tmux popup (`prefix + e`, or `prefix + E` for the current directory only) listing the files Claude Code recently wrote, with a diff of what Claude changed in the preview; `enter` opens the file in Vim, where `,d` shows a `git diff`-style view of Claude's changes and `,D` a side-by-side diff (`ctrl+d` in the list opens the diff straight away). Fed by the [`log-edits`](https://github.com/LionelPinheiroDuarte/agents/tree/main/hooks/log-edits) hook from agents
- **`claude-projects`** — tmux popup (`prefix + P`) to work with Claude Code on several projects at once: one tmux session per repo of `$GITHUB`, with a `claude` window and a `shell` window. `enter` jumps to the project (creating its session), `ctrl-x` closes one; the preview shows the branch, pending changes and last commits. Open projects are remembered, and `claude-projects restore` brings them back after a reboot with `claude --continue`, so each one resumes its last conversation. Also `claude-projects open [dir]` for a directory outside `$GITHUB`

## Credits

Thanks to [rwxrob](https://github.com/rwxrob/dot) for the bash, vim, and tmux foundations.
