#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

ref="$(tr -d '[:space:]' < UPSTREAM)"
rm -rf upstream
git init -q upstream
git -C upstream fetch -q --depth 1 https://github.com/balloob/home-assistant-addons.git "$ref"
git -C upstream checkout -q FETCH_HEAD
version="$(sed -n 's/^version: *"\{0,1\}\([^"]*\)"\{0,1\} *$/\1/p' upstream/puppet/config.yaml)"

echo "Building ha-puppet:local from upstream ${ref} (Puppet ${version})"
docker build \
  --build-arg UPSTREAM_REVISION="$ref" \
  --build-arg UPSTREAM_VERSION="$version" \
  -t ha-puppet:local \
  "$@" .
