#!/usr/bin/env bash
#
# Local checks for this repo. Run it when you want them:
#   ./scripts/ci.sh
# It is not a git hook and it does not run on push.
#
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Use the go1.18 command. The default `go` on PATH may be a newer release.
if ! command -v go1.18 >/dev/null 2>&1; then
	echo "Go 1.18 is required. The go1.18 command was not found." >&2
	echo "Install Go 1.18.10 from https://go.dev/dl/#go1.18.10" >&2
	exit 1
fi
go_ver=$(go1.18 version | awk '{print $3}')
if [[ "$go_ver" != go1.18 && "$go_ver" != go1.18.* ]]; then
	echo "Go 1.18 is required. go1.18 reports ${go_ver}." >&2
	echo "Install Go 1.18.10 from https://go.dev/dl/#go1.18.10" >&2
	exit 1
fi
# `make lint` calls `go`, and formatting uses `gofmt`. Both live in this SDK.
export PATH="$(go1.18 env GOROOT)/bin:${PATH}"

step() {
	echo "==> $1"
}

step "upstream pin"
git merge-base --is-ancestor 014cdcf09844d48f6d30f3e520034b7edffd9670 HEAD
grep -q 'TMVersionDefault = "0.34.24"' version/version.go

step "build"
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
CGO_ENABLED=0 go1.18 build -mod=readonly -trimpath -tags tendermint \
	-o "$build_dir/tendermint" ./cmd/tendermint

step "test"
go1.18 test -mod=readonly -p 1 -count=1 -tags deadlock ./...

step "lint"
make lint

step "format"
unformatted=$(
	find . -name '*.go' -type f \
		-not -path '*/.git/*' \
		-not -name '*.pb.go' \
		-not -name '*pb_test.go' \
		-exec gofmt -l {} +
)
if [[ -n "$unformatted" ]]; then
	printf '%s\n' "$unformatted" >&2
	echo "gofmt would change the files above" >&2
	exit 1
fi

step "modules"
go1.18 mod verify
mod_dir=$(mktemp -d)
cp go.mod go.sum "$mod_dir/"
go1.18 mod tidy
if ! cmp -s go.mod "$mod_dir/go.mod" || ! cmp -s go.sum "$mod_dir/go.sum"; then
	diff -u "$mod_dir/go.mod" go.mod || true
	diff -u "$mod_dir/go.sum" go.sum || true
	cp "$mod_dir/go.mod" go.mod
	cp "$mod_dir/go.sum" go.sum
	rm -rf "$mod_dir"
	echo "go1.18 mod tidy would change go.mod or go.sum" >&2
	exit 1
fi
rm -rf "$mod_dir"

step "vulnerabilities"
go1.18 run golang.org/x/vuln/cmd/govulncheck@v1.0.4 ./...

echo "ok"
