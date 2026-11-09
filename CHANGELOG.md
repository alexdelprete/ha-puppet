# Changelog

All notable changes to this image are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/). Each release states the upstream Puppet version it packages.

## [Unreleased]

### Added

- Standalone image of upstream Puppet 2.6.1 (balloob/home-assistant-addons@78c26e1) for linux/amd64 and linux/arm64.
- Configuration from `HA_URL`, `HA_TOKEN`, `HA_TOKEN_FILE` and `KEEP_BROWSER_OPEN`, written to `/data/options.json` at start.
- Runs as non-root `node` (uid 1000) under tini, with a healthcheck.
- Semver release workflow: GHCR tags `X.Y.Z`, `X.Y`, `X`, `latest`, SBOM and provenance attestations, cosign signature, GitHub release.
- Daily upstream check that test-builds new upstream revisions and opens a pull request.
