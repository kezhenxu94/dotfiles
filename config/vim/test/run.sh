#!/usr/bin/env bash
# Run the Vim config tests: every test_*.vim (or the ones given as arguments)
# in a fresh Vim loading this repository's config (not the installed links).
#
#   config/vim/test/run.sh                  # all tests
#   config/vim/test/run.sh test_go.vim      # one file
#   VIM_TEST_FILTER=Motion run.sh           # only Test_* functions matching
#   VIM=/path/to/vim VIM_TEST_TIMEOUT=600 run.sh
set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="$(cd "$TEST_DIR/../.." && pwd)"
VIM="${VIM:-vim}"
TIMEOUT="${VIM_TEST_TIMEOUT:-300}"
export VIM_TEST_FILTER="${VIM_TEST_FILTER:-}"
export VIM_TEST_XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

cd "$TEST_DIR" || exit 1
files=("$@")
[ ${#files[@]} -eq 0 ] && files=(test_*.vim)

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Vim needs a terminal; run it under script(1) (util-linux or BSD flavour).
run_in_pty() {
  if script --version >/dev/null 2>&1; then
    script -qec "$(printf '%q ' "$@")" /dev/null
  else
    script -q /dev/null "$@"
  fi
}

failed=0
for file in "${files[@]}"; do
  out="$TMP/${file%.vim}.out"
  export VIM_TEST_OUT="$out" VIM_TEST_TMP="$TMP/${file%.vim}"
  mkdir -p "$VIM_TEST_TMP/cwd"
  # Isolate caches (e.g. the jdtls workspace) and state (the session restored
  # per working directory) from the real ones and from other test files.
  # The env goes inside the pty command: script(1) starts $SHELL, whose startup
  # files (e.g. zshenv) could reset XDG_CONFIG_HOME.
  (cd "$VIM_TEST_TMP/cwd" && timeout "$TIMEOUT" bash -c "$(declare -f run_in_pty); run_in_pty \"\$@\"" _ \
    env XDG_CONFIG_HOME="$CONFIG_HOME" XDG_CACHE_HOME="$TMP/cache" XDG_STATE_HOME="$VIM_TEST_TMP/state" "$VIM" -N -u "$CONFIG_HOME/vim/vimrc" -i NONE \
    --cmd "set rtp^=$CONFIG_HOME/vim rtp+=$CONFIG_HOME/vim/after packpath^=$CONFIG_HOME/vim" \
    -S "$TEST_DIR/$file" </dev/null >/dev/null 2>&1)
  status=$?

  if [ ! -s "$out" ]; then
    echo "FAIL $file: no results (exit $status$([ $status -eq 124 ] && echo ", timed out after ${TIMEOUT}s"))"
    failed=1
    continue
  fi
  while IFS= read -r line; do
    name=$(jq -r .name <<<"$line")
    ms=$(jq -r .ms <<<"$line")
    if [ "$(jq '.errors | length' <<<"$line")" -eq 0 ]; then
      echo "ok   $file $name (${ms}ms)"
    else
      echo "FAIL $file $name"
      jq -r '.errors[] | "     " + .' <<<"$line"
      failed=1
    fi
  done <"$out"
  if [ $status -eq 124 ]; then
    echo "FAIL $file: timed out after ${TIMEOUT}s (after the last result above)"
    failed=1
  fi
done

exit $failed
