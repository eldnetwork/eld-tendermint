# How this differs from upstream

Branch `eld/v0.34.24` starts at upstream Tendermint Core `v0.34.24`, commit `014cdcf09844d48f6d30f3e520034b7edffd9670`.

No Go code is changed. The Eld layer is packaging and docs:

- `README.md`, `NOTICE`, `SECURITY.md`, and this file replace the upstream landing pages.
- `Dockerfile` and `.dockerignore` build the Eld runtime image. They do not use `DOCKER/Dockerfile`.
- `.github/workflows/image.yml` is the only GitHub Actions workflow. Upstream CircleCI, AppVeyor, Codecov, Mergify, and Goreleaser configs are not on this branch.

`upstream/v0.34.24` stays the unmodified import.

## Tests

Release gate is Go 1.18: `go build ./cmd/tendermint`, then `go test -tags deadlock` of `crypto`, `consensus`, `types`, `mempool`, `p2p`, `state`, and `node`. `./scripts/ci.sh` runs that gate locally. GitHub Actions builds `./cmd/tendermint` and runs `./scripts/ci.sh test` on Linux and macOS. Test sources are unchanged. These are upstream tests, not Eld patches.

Outside the gate:

- `./light` — header time from the future / clock drift under CI load. Eld runs a full node for ABCI and does not need the light-client unit suite to ship images.
- `light/provider/http` `TestProvider` — local node shutdown race. The node is already tearing down, so the check expects "height requested is too high" and gets "light block not found".
- `state/indexer/sink/psql` — needs Docker and an exclusive published port. Fails with address already in use.

Observed on Darwin, not skipped on Linux:

- `TestBroadcastTxForPeerStopsWhenReactorStops` — leaktest / go-deadlock flake
- `TestTxMempool_ExpiredTxs_Timestamp` — wall-clock TTL flake
- `TestPartValidateBasic` — times out under `-tags deadlock` while filling a large random buffer
