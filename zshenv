# Install prefix for source builds and mise tools: shared with the staff group once bootstrap has
# created /opt/staff (see packages/install/lib/env.sh), per-user otherwise
if [[ -z $USR_HOME ]]; then
  if [[ -r /opt/staff ]]; then USR_HOME=/opt/staff; else USR_HOME=~/usr/local; fi
fi
export USR_HOME
if [[ $USR_HOME == /opt/staff ]]; then
  export MISE_SYSTEM_DATA_DIR=$USR_HOME/share/mise
  # Rust toolchains are shared too; CARGO_HOME stays per user (setup.sh links the rustup proxies into it)
  export RUSTUP_HOME=$USR_HOME/share/rustup
fi

export PATH="$HOME/.bin:$HOME/.local/bin:$USR_HOME/bin:$PATH"
export PATH="$HOME/.bin/kfc:$PATH"
export PATH="$HOME/.bin/hif:$PATH"
export PATH="$PATH:$HOME/.local/share/solana/install/active_release/bin"

export XDG_CONFIG_HOME=~/.config
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export ASDF_GOLANG_MOD_VERSION_ENABLED=true

if ls $USR_HOME/lib > /dev/null 2>&1; then
  export LD_LIBRARY_PATH=$USR_HOME/lib:$LD_LIBRARY_PATH
  export DYLD_LIBRARY_PATH=$USR_HOME/lib:$DYLD_LIBRARY_PATH
  export ACLOCAL_PATH=$USR_HOME/share/aclocal:$ACLOCAL_PATH
  export CPPFLAGS="-I$USR_HOME/include${CPPFLAGS:+ $CPPFLAGS}"
  export LDFLAGS="-L$USR_HOME/lib${LDFLAGS:+ $LDFLAGS}"
  export PKG_CONFIG_PATH=$USR_HOME/lib/pkgconfig:$USR_HOME/lib64/pkgconfig:$PKG_CONFIG_PATH
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

export MYSQL_HOME=$USR_HOME/mysql
export MYSQLCLIENT_CFLAGS="-I$MYSQL_HOME/include"
export MYSQLCLIENT_LDFLAGS="-L$MYSQL_HOME/lib -lmysqlclient"
