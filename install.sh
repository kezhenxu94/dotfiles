#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

should_ignore() {
  local file="$1"
  if [[ -f ".installignore" ]]; then
    while IFS= read -r pattern || [[ -n "$pattern" ]]; do
      [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
      if [[ "$file" == $pattern ]]; then
        return 0
      fi
    done <.installignore
  fi
  return 1
}

git -C "$SCRIPT_DIR" submodule update --init

git -C "$SCRIPT_DIR" ls-files | while read file; do
  should_ignore "$file" && continue

  target="$HOME/.$file"
  [[ $file == .* ]] && target="$HOME/$file"

  mkdir -p "$(dirname "$target")"
  ln -sf "$SCRIPT_DIR/$file" "$target"
done

