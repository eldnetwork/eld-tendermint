# How this differs from upstream

Branch `eld/v0.34.24` starts at upstream Tendermint Core `v0.34.24`, commit `014cdcf09844d48f6d30f3e520034b7edffd9670`.

No Go code is changed. The Eld layer is packaging and docs:

- `README.md`, `NOTICE`, `SECURITY.md`, and this file replace the upstream landing pages.
- `Dockerfile` and `.dockerignore` build the Eld runtime image. They do not use `DOCKER/Dockerfile`.
- `.github/workflows/image.yml` is the only GitHub Actions workflow. Upstream CircleCI, AppVeyor, Codecov, Mergify, and Goreleaser configs are not on this branch.

`upstream/v0.34.24` stays the unmodified import.
