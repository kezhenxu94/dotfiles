#!/usr/bin/env bash
# Main orchestrator for package installation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Global cleanup function for interrupted downloads
cleanup_temp_files() {
  # Clean up any temp files created by this process
  rm -f /tmp/*.tmp.$$
  rm -rf /tmp/*-*.$$
  rm -f "$HOME/.bin/"*.tmp.$$
}

# Set up trap to cleanup on exit, interrupt, or termination
trap cleanup_temp_files EXIT INT TERM

# Source libraries
source "$SCRIPT_DIR/lib/env.sh"
source "$SCRIPT_DIR/lib/helpers.sh"

# Handle skip flag
if [ "${SKIP_INSTALL:-false}" != "false" ]; then
  echo "Skipping install..."
  exit 0
fi

echo "==> Starting package installation"

# Discover all package files and sort by filename
# Package files should use numeric prefixes (e.g., 00-kubectl.sh, 10-m4.sh)
# to control installation order
shopt -s nullglob
packages=("$SCRIPT_DIR/packages/"*.sh)
shopt -u nullglob

if [ ${#packages[@]} -eq 0 ]; then
  echo "No packages found in $SCRIPT_DIR/packages/"
  exit 0
fi

# Sort packages by filename (compatible with bash 3.2+)
sorted_packages=()
while IFS= read -r -d '' file; do
  sorted_packages+=("$file")
done < <(printf '%s\0' "${packages[@]}" | sort -z)

echo "==> Found ${#sorted_packages[@]} packages"

# Install in filename order
for pkg_file in "${sorted_packages[@]}"; do
  pkg_basename=$(basename "$pkg_file" .sh)
  echo "==> Processing: $pkg_basename"

  # Source the package file (which will execute the install function)
  # shellcheck disable=SC1090
  source "$pkg_file"
done

echo ""
echo "==> Installation complete!"
