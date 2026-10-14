export PATH="$HOME/.bin:$HOME/.local/bin:$HOME/usr/local/bin:$PATH"
export PATH="$HOME/.bin/kfc:$PATH"
export PATH="$HOME/.bin/hif:$PATH"
export PATH="$HOME/usr/local/nvim/bin:$PATH"
export PATH="$HOME/usr/local/nvim-nightly/bin:$PATH"
export PATH="$PATH:$HOME/.local/share/solana/install/active_release/bin"
export PATH="$PATH:$HOME/.fzf/bin"

export XDG_CONFIG_HOME=~/.config
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export ASDF_GOLANG_MOD_VERSION_ENABLED=true

if ls ~/usr/local/lib > /dev/null 2>&1; then
  export LD_LIBRARY_PATH=~/usr/local/lib:$LD_LIBRARY_PATH
  export DYLD_LIBRARY_PATH=~/usr/local/lib:$DYLD_LIBRARY_PATH
  export ACLOCAL_PATH=~/usr/local/share/aclocal:$ACLOCAL_PATH
  export CPPFLAGS="-I$HOME/usr/local/include${CPPFLAGS:+ $CPPFLAGS}"
  export LDFLAGS="-L$HOME/usr/local/lib${LDFLAGS:+ $LDFLAGS}"
  export PKG_CONFIG_PATH=~/usr/local/lib/pkgconfig:~/usr/local/lib64/pkgconfig:$PKG_CONFIG_PATH
fi

local _old_path="$PATH"

# Local config
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local

if [[ $PATH != $_old_path ]]; then
  print -u2 "Warning: ~/.zshenv.local edits PATH; move it to ~/.zshrc.local"
fi

unset _old_path

LC_CTYPE=en_US.UTF-8
LC_ALL=en_US.UTF-8

export MYSQL_HOME=~/usr/local/mysql
export MYSQLCLIENT_CFLAGS="-I$MYSQL_HOME/include"
export MYSQLCLIENT_LDFLAGS="-L$MYSQL_HOME/lib -lmysqlclient"
