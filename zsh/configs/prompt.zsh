#!/usr/bin/env zsh

# Function to set prompt - will be called before each prompt
precmd() {
    if [[ "$THEME" == "light" ]]; then
        # Light theme colors (matching tmux theme-light.conf)
        # Using @accent-color "#2563eb" for directory
        # Using @fg-color "#2c3e50" for prompt symbol
        PS1="%B%F{#2563eb}%~%f%b %F{#2c3e50}%(!.#.❯)%f "
    else
        # Dark theme colors (matching tmux theme-dark.conf)
        # Using @accent-color "#7aa2f7" for directory
        # Using @fg-color "#c0caf5" for prompt symbol
        PS1="%B%F{#7aa2f7}%~%f%b %F{#c0caf5}%(!.#.❯)%f "
    fi
}
