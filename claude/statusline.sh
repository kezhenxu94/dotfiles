#!/bin/sh
# Claude Code status line: org name and subscription usage.
org=$(jq -r '.oauthAccount.organizationName // empty' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.claude.json")

jq -r --arg org "$org" '.rate_limits // {} | [
  ($org | select(. != "")),
  (.five_hour.used_percentage | select(.) | "\(round)%/5h"),
  (.seven_day.used_percentage | select(.) | "\(round)%/7d")
] | select(length > 0) | join(" ")'
