#!/usr/bin/env bash
# Python-based formatter (black) and linter (yamllint).
# Prefers `uv tool` / `pipx` so bins land in ~/.local/bin (on $PATH); falls back
# to `pip install --user`. No-ops when no Python installer is available.

pkg_name="lsp-pip"
pkg_version="latest"

install_lsp_pip() {
  local tools=(black yamllint)

  # Drop tools already on $PATH so nothing is reinstalled.
  local missing=()
  local t
  for t in "${tools[@]}"; do
    check_installed "$t" || missing+=("$t")
  done
  if [ ${#missing[@]} -eq 0 ]; then
    echo "python LSP tools already installed"
    return 0
  fi
  tools=("${missing[@]}")

  if check_installed uv; then
    local t
    for t in "${tools[@]}"; do
      uv tool install "$t" || return 1
    done
    return 0
  fi

  if check_installed pipx; then
    local t
    for t in "${tools[@]}"; do
      pipx install "$t" || return 1
    done
    return 0
  fi

  if check_installed pip3 || check_installed pip; then
    local pip_cmd
    pip_cmd="$(command -v pip3 || command -v pip)"
    echo "uv/pipx not found; using ${pip_cmd} --user (ensure its bin dir is on \$PATH)"
    "$pip_cmd" install --user "${tools[@]}" || return 1
    return 0
  fi

  echo "no uv/pipx/pip found; skipping python LSP tools"
  return 0
}

install_lsp_pip
