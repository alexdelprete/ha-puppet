# ha-puppet

[![CI](https://github.com/alexdelprete/ha-puppet/actions/workflows/ci.yml/badge.svg)](https://github.com/alexdelprete/ha-puppet/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/alexdelprete/ha-puppet?sort=semver)](https://github.com/alexdelprete/ha-puppet/releases)

Standalone, multi-arch container image of [Puppet](https://github.com/balloob/home-assistant-addons/tree/main/puppet), the Home Assistant dashboard screenshot service written by Paulus Schoutsen (balloob).

Upstream ships Puppet only as a Home Assistant add-on, which Supervisor builds locally. This repository packages the same code as a ready-to-pull image for Home Assistant Container, Docker, Podman or Kubernetes installs, for example as the screenshot engine of [ha-mcp](https://github.com/homeassistant-ai/ha-mcp).

```
ghcr.io/alexdelprete/ha-puppet
```

The Puppet source is not vendored or modified. Every build checks out the upstream revision pinned in [`UPSTREAM`](UPSTREAM).

## What this image adds

- **Pinned upstream**: the exact upstream commit and Puppet version are recorded in the image labels and in every release note.
- **Semver releases**: immutable `X.Y.Z` tags, plus moving `X.Y`, `X` and `latest`.
- **amd64 and arm64**.
- **Non-root**: runs as `node` (uid 1000). Upstream launches Chromium with `--no-sandbox`, so not running as root matters.
- **Configuration from environment**: no options file to hand-craft; Docker secrets supported.
- **Healthcheck** and **tini** as init (reaps Chromium child processes).
- **Supply chain**: SBOM and provenance attestations, GitHub artifact attestation, keyless cosign signature.
- **Upstream tracking**: a daily workflow test-builds new upstream revisions and opens a pull request.

## Usage

```yaml
services:
  ha-puppet:
    image: ghcr.io/alexdelprete/ha-puppet:1
    container_name: ha-puppet
    restart: unless-stopped
    environment:
      HA_URL: http://host.docker.internal:8123
      HA_TOKEN_FILE: /run/secrets/ha_token
      TZ: Europe/Rome
    secrets:
      - ha_token
    extra_hosts:
      - "host.docker.internal:host-gateway"
    ports:
      - "127.0.0.1:10000:10000"

secrets:
  ha_token:
    file: ./ha_token
```

Then open `http://127.0.0.1:10000/` for the UI, or request a screenshot directly, e.g. `http://127.0.0.1:10000/lovelace/0?viewport=1000x1000`. See the [upstream README](https://github.com/balloob/home-assistant-addons/blob/main/puppet/README.md) for all URL parameters.

Use a long-lived access token from a dedicated, non-admin Home Assistant user: theme changes Puppet applies affect every session of the user whose token it uses.

### Configuration

| Variable | Default | Description |
|---|---|---|
| `HA_URL` | `http://homeassistant:8123` | Home Assistant URL as seen from the container |
| `HA_TOKEN` | | Long-lived access token |
| `HA_TOKEN_FILE` | | File containing the token (Docker or Kubernetes secret); used when `HA_TOKEN` is not set |
| `KEEP_BROWSER_OPEN` | `false` | Keep Chromium running between requests (faster, more memory) |
| `TZ` | `Etc/UTC` | Time zone used when rendering |

At start the entrypoint writes `/data/options.json`, the file upstream reads in add-on mode. Alternatively mount your own `/data/options.json` with the upstream keys (`access_token`, `home_assistant_url`, `keep_browser_open`); environment variables that are set override the matching keys, which requires the file to be writable.

### Security

Puppet's HTTP listener on port 10000 has **no authentication**, and anyone who can reach it can screenshot any Home Assistant page the token can see. Publish it on `127.0.0.1` or keep it on an internal container network; never expose it to the internet.

## Versions

Image versions follow [Semantic Versioning](https://semver.org) and are independent of the upstream Puppet version, which every release note states.

- **Major**: breaking changes to how the container is run (variables, paths, user, port).
- **Minor**: a new upstream Puppet release, or new image features.
- **Patch**: base image, dependency or upstream fix updates.

Pin `X.Y.Z` or a digest for reproducible deployments; `X` follows non-breaking updates.

### Verify an image

```
gh attestation verify oci://ghcr.io/alexdelprete/ha-puppet:1.0.0 --owner alexdelprete
cosign verify ghcr.io/alexdelprete/ha-puppet:1.0.0 \
  --certificate-identity-regexp '^https://github.com/alexdelprete/ha-puppet/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

## Building locally

```
./scripts/build-local.sh
```

Fetches the pinned upstream revision into `upstream/` and builds `ha-puppet:local`. Extra arguments go to `docker build`.

## Credits and license

Puppet is written by [Paulus Schoutsen](https://github.com/balloob) and published under the Apache License 2.0 in [balloob/home-assistant-addons](https://github.com/balloob/home-assistant-addons). This repository only adds packaging, under the same [license](LICENSE). It is not affiliated with or endorsed by the upstream author or the Home Assistant project.
