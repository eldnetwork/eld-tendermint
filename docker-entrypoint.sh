#!/bin/sh
set -e
if [ "$1" = "tendermint" ] && [ "$2" = "node" ] && [ -n "${PROXY_APP}" ]; then
  shift 2
  exec tendermint node --proxy_app="${PROXY_APP}" "$@"
fi
exec "$@"
