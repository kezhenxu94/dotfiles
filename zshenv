export PATH="$HOME/.bin:$HOME/.local/bin:$HOME/usr/local/bin:$PATH"
export PATH="$HOME/usr/local/nvim/bin:$PATH"
export PATH="$HOME/usr/local/nvim-nightly/bin:$PATH"
export PATH="$PATH:$HOME/.local/share/nvim/mason/bin"

export XDG_CONFIG_HOME=~/.config
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export K9SCONFIG=~/.config/k9s
export ASDF_GOLANG_MOD_VERSION_ENABLED=true

if ls ~/usr/local/lib > /dev/null 2>&1; then
  export LD_LIBRARY_PATH=~/usr/local/lib:$LD_LIBRARY_PATH
  export DYLD_LIBRARY_PATH=~/usr/local/lib:$DYLD_LIBRARY_PATH
fi

local _old_path="$PATH"

# Local config
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local

if [[ $PATH != $_old_path ]]; then
  # `colors` isn't initialized yet, so define a few manually
  typeset -AHg fg fg_bold
  if [ -t 2 ]; then
    fg[red]=$'\e[31m'
    fg_bold[white]=$'\e[1;37m'
    reset_color=$'\e[m'
  else
    fg[red]=""
    fg_bold[white]=""
    reset_color=""
  fi

  cat <<MSG >&2
${fg[red]}Warning:${reset_color} your \`~/.zshenv.local' configuration seems to edit PATH entries.
Please move that configuration to \`.zshrc.local' like so:
  ${fg_bold[white]}cat ~/.zshenv.local >> ~/.zshrc.local && rm ~/.zshenv.local${reset_color}

(called from ${(%):-%N:%i})

MSG
fi

unset _old_path

LC_CTYPE=en_US.UTF-8
LC_ALL=en_US.UTF-8

export MYSQL_HOME=~/usr/local/mysql
export MYSQLCLIENT_CFLAGS="-I$MYSQL_HOME/include"
export MYSQLCLIENT_LDFLAGS="-L$MYSQL_HOME/lib -lmysqlclient"
