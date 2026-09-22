#!/usr/bin/env zsh

# Sets proxy env vars based on whether xray (started by the
# io.kezhenxu94.v2ray LaunchAgent, see bin/v2rayx) is currently running,
# instead of trusting a value written by that LaunchAgent at some
# unpredictable point after login.
# Set `127.0.0.1 host.docker.internal` in /etc/hosts to make this work in Docker containers too,
# change `host.docker.internal` to `127.0.0.1` if you don't want to use the host.docker.internal hostname.
if pgrep -qf xray; then
  export HTTPS_PROXY=http://host.docker.internal:7890
  export HTTP_PROXY=http://host.docker.internal:7890
  export ALL_PROXY=socks5://host.docker.internal:7891
  export NO_PROXY="127.0.0.1,192.168.0.0/16,10.0.0.0/8,host.docker.internal,*.apple.com,.local,localhost,local-docker-registry,pi5,kind-control-plane" # Don't proxy *.apple.com for "Translate" application to work
  export https_proxy=$HTTPS_PROXY
  export http_proxy=$HTTP_PROXY
  export all_proxy=$ALL_PROXY
  export no_proxy=$NO_PROXY
else
  unset HTTPS_PROXY HTTP_PROXY ALL_PROXY NO_PROXY https_proxy http_proxy all_proxy no_proxy
fi
