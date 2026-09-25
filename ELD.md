# How this differs from upstream

Branch `eld/v0.34.24` starts at upstream Tendermint Core `v0.34.24`, commit `014cdcf09844d48f6d30f3e520034b7edffd9670`.

No Go code is changed. The Eld layer is packaging and docs:

- `README.md`, `NOTICE`, `SECURITY.md`, and this file replace the upstream landing pages.
- `Dockerfile` and `.dockerignore` build the Eld runtime image. They do not use `DOCKER/Dockerfile`.
- `.github/workflows/image.yml` is the only GitHub Actions workflow. Upstream CircleCI, AppVeyor, Codecov, Mergify, and Goreleaser configs are not on this branch.

`upstream/v0.34.24` stays the unmodified import.

## Tests

`./scripts/ci.sh` runs the upstream suite with Go 1.18 and `-tags deadlock`. GitHub Actions runs `./scripts/ci.sh test` on Linux and macOS. Test sources are unchanged.

On macOS these upstream tests are skipped. Linux still runs them.

- `TestBroadcastTxForPeerStopsWhenReactorStops` — leaktest / go-deadlock flake
- `TestTxMempool_ExpiredTxs_Timestamp` — wall-clock TTL flake
- `state/indexer/sink/psql` — needs Docker; fails when port 5432 is taken
- `TestPartValidateBasic` — times out under `-tags deadlock` while filling a large random buffer
