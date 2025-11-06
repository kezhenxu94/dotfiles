#!/usr/bin/env zsh

# Function to set prompt - will be called before each prompt
precmd() {
    # Get virtual environment info
    local venv=""
    if [[ -n "$VIRTUAL_ENV" ]]; then
        venv="(${VIRTUAL_ENV:t}) "  # :t modifier gets the tail (basename) of the path
    fi

    if [[ "$THEME" == "light" ]]; then
        # Light theme colors (matching tmux theme-light.conf)
        # Using @accent-color "#2563eb" for directory
        # Using @fg-color "#2c3e50" for prompt symbol
        PS1="${venv}%B%F{#2563eb}%~%f%b %F{#2c3e50}%(!.#.❯)%f "

        export FZF_THEME=" \
        --color=bg+:#CCD0DA,spinner:#DC8A78,hl:#D20F39 \
        --color=fg:#4C4F69,header:#D20F39,info:#8839EF,pointer:#DC8A78 \
        --color=marker:#7287FD,fg+:#4C4F69,prompt:#8839EF,hl+:#D20F39 \
        --color=selected-bg:#BCC0CC \
        --color=border:#9CA0B0,label:#4C4F69"
        export K9S_SKIN=catppuccin-latte-transparent
    else
        # Dark theme colors (matching tmux theme-dark.conf)
        # Using @accent-color "#7aa2f7" for directory
        # Using @fg-color "#c0caf5" for prompt symbol
        PS1="${venv}%B%F{#7aa2f7}%~%f%b %F{#c0caf5}%(!.#.❯)%f "

        export FZF_THEME=" \
        --color=bg+:#313244,spinner:#F5E0DC,hl:#F38BA8 \
        --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
        --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
        --color=selected-bg:#45475A \
        --color=border:#6C7086,label:#CDD6F4"
        export K9S_SKIN=catppuccin-mocha-transparent
    fi
}
