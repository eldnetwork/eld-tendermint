# eld-tendermint

Pinned [Tendermint Core](https://github.com/tendermint/tendermint) **v0.34.24**
used as the consensus engine for [eld-chain](https://github.com/eldnetwork/eld-chain).

This repository is a packaging and image build of that upstream tag.
It is not Tendermint Inc / Interchain, and it is not a new consensus protocol.

```text
Upstream: github.com/tendermint/tendermint
Tag:      v0.34.24
Commit:   014cdcf09844d48f6d30f3e520034b7edffd9670
License:  Apache-2.0
```

## Image

`ghcr.io/eldnetwork/eld-tendermint:v0.34.24-eld.1`

## Publish

Push the commit to `eld` first. `origin` is upstream Tendermint and rejects this tag.

```sh
git tag -a v0.34.24-eld.2 -m "eld-tendermint v0.34.24-eld.2"
git push eld v0.34.24-eld.2
```

The first argument is the remote. A tag matching `v0.34.24-eld.*` starts GitHub Actions. The image is published only after the verify and test jobs pass.

## What this is

| | |
|---|---|
| Upstream project | Tendermint Core |
| Upstream tag | v0.34.24 |
| Upstream commit | `014cdcf09844d48f6d30f3e520034b7edffd9670` |
| ABCI | 0.17.0 |
| License | Apache-2.0. The Go tree and the Eld packaging files (`Dockerfile`, `NOTICE`, `ELD.md`, this README) are Apache-2.0. |

Upstream changelog: [CHANGELOG.md](CHANGELOG.md). How this tree differs from that commit: [ELD.md](ELD.md).

## Run

The binary is `tendermint`. Config, genesis, and validator keys are not in the image. Mount them at `$TMHOME` (default `/tendermint/.tendermint`).

`proxy_app` comes from the mounted `config.toml`. If `PROXY_APP` is set, the entrypoint passes it as `--proxy_app`. The image does not default to the `kvstore` app.

eld-chain Compose mounts that config from `deploy/docker/local/`.

## Build locally

```sh
docker build -t ghcr.io/eldnetwork/eld-tendermint:local .
```

## Security

Upstream Tendermint issues: follow upstream policy for 0.34.
Eld packaging, image, and deploy issues: GitHub Security Advisories on this repo or [eld-chain](https://github.com/eldnetwork/eld-chain). Do not open a public issue for key material.

See [SECURITY.md](SECURITY.md).

## Patches

None beyond packaging.
