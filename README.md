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
- **Versioned builds**: every published image has an immutable tag naming the upstream Puppet version and the build, and is only published when something inside it changed (see [Tags](#tags)).
- **amd64 and arm64**.
- **Non-root**: runs as `node` (uid 1000). Upstream launches Chromium with `--no-sandbox`, so not running as root matters.
- **Configuration from environment**: no options file to hand-craft; Docker secrets supported.
- **Healthcheck** and **tini** as init (reaps Chromium child processes).
- **Supply chain**: SBOM and provenance attestations, GitHub artifact attestation, keyless cosign signature.
- **Upstream tracking**: a daily workflow test-builds new upstream revisions and opens a pull request; a daily rebuild publishes Debian (Chromium) security updates.

## Usage

```yaml
services:
  ha-puppet:
    image: ghcr.io/alexdelprete/ha-puppet:latest
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

## Tags

Every published build gets one immutable tag and moves two others.

```
2.6.1-1.3     immutable   this exact build
2.6.1-1       moving      the newest build of Puppet 2.6.1, packaging revision 1
latest        moving      the newest build of anything
```

The immutable tag is read as `<Puppet version>-<packaging revision>.<build>`:

- `2.6.1` is the upstream Puppet version, from `puppet/config.yaml` in [balloob/home-assistant-addons](https://github.com/balloob/home-assistant-addons) at the revision pinned in [`UPSTREAM`](UPSTREAM).
- `-1` is this repository's packaging revision, kept in [`PACKAGING`](PACKAGING). It changes only for breaking changes to how the container is run (environment variables, paths, user, port), the role Debian's packaging revision plays for a distribution package.
- `.3` is the build number: the third published image of that Puppet version and packaging revision. It increments when anything else inside the image changes: Debian packages (Chromium security updates are the usual reason), the Node base image, npm dependencies, a new upstream commit without a version bump, or this repository's build inputs. It resets to `.1` when the Puppet version or the packaging revision changes.

A build is published only when its manifest differs from the previous release's. The daily build compares the installed Debian and npm package versions, Node, the upstream revision and a hash of the build inputs, and publishes nothing when they are identical. Each release lists what changed and attaches the full `manifest.txt`.

Pin the immutable tag for reproducibility, the moving `2.6.1-1` tag to receive security rebuilds without editing your compose file, or `latest` to receive everything.

The version is stamped into the image, so a running container can say what it is regardless of the tag it was started from:

```
docker inspect ha-puppet --format '{{index .Config.Labels "org.opencontainers.image.version"}}'
docker logs ha-puppet 2>&1 | grep 'ha-puppet '
```

The first returns the immutable tag, the second the boot line `[ha-puppet] ha-puppet 2.6.1-1.3, Puppet 2.6.1`. `org.opencontainers.image.revision` holds the commit of this repository it was built from.

### SemVer

The tags are valid Semantic Versioning 2.0.0: the Puppet version is major.minor.patch, and `<packaging>.<build>` is the prerelease field, compared as dot-separated numeric identifiers:

```
2.6.1-1  <  2.6.1-1.1  <  2.6.1-1.2  <  2.6.1-1.10  <  2.6.1-2.1  <  2.6.2-1.1
```

The moving `2.6.1-1` tag sorts below every build it points to, so an update checker watching an immutable tag never offers it as an update. This was checked against the tag comparison code of What's Up Docker (`isGreater` in getwud/wud, November 2026). A bare moving `2.6.1` tag would not have that property: WUD ranks a bare tag above any suffixed tag with the same version.

### Verify an image

```
gh attestation verify oci://ghcr.io/alexdelprete/ha-puppet:2.6.1-1.1 --owner alexdelprete
cosign verify ghcr.io/alexdelprete/ha-puppet:2.6.1-1.1 \
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
