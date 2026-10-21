---
name: workflow-plugin-ideas
description: Mine the user's dotfiles, shell/REPL/editor history and project scripts to propose Vim/Neovim, zsh or tmux plugins (or features for their existing plugins) that would ease their real workflow. Use when the user asks what plugins/tools to build or adopt, or how to streamline a workflow.
---

# Workflow plugin ideas

Propose plugins grounded in evidence of real usage, not generic lists.

## 1. Inventory the setup (~/dotfiles)
- Neovim: `config/nvim` (`vim.pack` in `nvim-pack-lock.json`), Vim: `config/vim` (packs are submodules, see `.gitmodules`).
- Shell: `aliases`, `config/zsh/{configs,functions}`, `bin/` (incl. submodules), `packages/install/packages` (installed CLIs).
- tmux: `config/tmux/tmux.conf`.
- The user's own plugins and tools (github.com/kezhenxu94): kube.nvim, docker.nvim, mongo.vim, kfc, hif, ghf. Read their READMEs to learn what's covered and the house style.

## 2. Mine histories
- zsh is per directory: `~/.zsh_history_dirs/*` (`: <ts>:0;<cmd>`). Use `LC_ALL=C`. The directory name encodes the project path.
- REPLs: `~/.psql_history`, `~/.sqlite_history`, `~/.python_history`, `~/.node_repl_history`, `~/.mongodb/mongosh/`.
- Editor: recent files from shada (`nvim --headless -c 'oldfiles' -c q`).
- Claude Code prompts: `~/.claude/history.jsonl` and `~/.claude-*/history.jsonl` (`.display`, `.project`). Look for tasks asked for repeatedly.
- Project scripts checked into `~/workspace/**` (`tests/*.sh`, `Makefile`, `scripts/`). These encode repeated workflows.

Look for:
- top commands and subcommands, and their flags;
- edit-and-rerun loops (the same command with small changes);
- long pipelines (`| jq`, `| grep`);
- copy and paste of IDs between commands;
- CLIs that have no editor or fzf integration yet.

## 3. Privacy
- Never print secrets. Redact tokens, JWTs and passwords in anything you show.
- Never read `.env` or credential files. Only note that they exist.

## 4. Check the landscape
For each candidate, research the existing Vim/Neovim/zsh/tmux plugins in a background agent:
- format and dependencies;
- Vim 9 support;
- maintenance and license changes;
- open complaints in their issues.

Drop crowded niches unless there's a clear differentiator. The user rejected an HTTP client for this reason; they prefer to keep curl in the shell.

## 5. Fit the house style
- Naming: `<tool>.nvim` if Neovim-only, `<tool>.vim` for Vim 9 + Neovim; one `:<Tool> <subcommand>` command.
- Zero dependencies besides the wrapped CLI.
- Preferred patterns:
  - buffers as the UI, where `:w` applies the change (kube.nvim);
  - run in place, with completion and hover from the live system (mongo.vim);
  - fzf wrappers for the shell (kfc, hif).
- Prefer a feature in an existing plugin over a new plugin when the domain overlaps (e.g. Helm went into kube.nvim).
- Never require changes that break the user's files. For example, scripts must stay runnable.

## 6. Report
Give a ranked list. For each idea:
- the evidence (counts and examples);
- what the plugin would look like;
- why it is different from existing tools;
- caveats.

Add a short "considered and skipped" list. Then ask which idea to dive into, and base the deep dive on the user's real files.
