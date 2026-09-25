#!/usr/bin/env bash
#
# Local checks for this repo. Run it when you want them:
#   ./scripts/ci.sh
# GitHub Actions runs the release-gate tests only:
#   ./scripts/ci.sh test
# It is not a git hook and it does not run on push.
#
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Prefer the go1.18 command when several Go versions are installed.
# GitHub Actions setup-go provides `go` at 1.18.10 and no go1.18 binary.
if command -v go1.18 >/dev/null 2>&1; then
	GO=go1.18
elif command -v go >/dev/null 2>&1; then
	GO=go
else
	echo "Go 1.18 is required. The go1.18 command was not found." >&2
	echo "Install Go 1.18.10 from https://go.dev/dl/#go1.18.10" >&2
	exit 1
fi
go_ver=$("$GO" version | awk '{print $3}')
if [[ "$go_ver" != go1.18 && "$go_ver" != go1.18.* ]]; then
	echo "Go 1.18 is required. ${GO} reports ${go_ver}." >&2
	echo "Install Go 1.18.10 from https://go.dev/dl/#go1.18.10" >&2
	exit 1
fi
# `make lint` calls `go`, and formatting uses `gofmt`. Both live in this SDK.
export PATH="$("$GO" env GOROOT)/bin:${PATH}"

step() {
	echo "==> $1"
}

# Release gate: crypto, consensus, types, mempool, p2p, state, and node.
# ./light and state/indexer/sink/psql are outside the gate.
# Go 1.18 has no go test -skip. On Darwin, drop the named tests with -run.
# Linux, including GitHub Actions, still runs those tests.
run_filtered() {
	local pkg=$1 skip=$2 names list re
	echo "skip test ${skip} in ${pkg}"
	names=$("$GO" test -mod=readonly -tags deadlock -list '.*' "$pkg")
	list=$(printf '%s\n' "$names" | grep -E '^(Test|Example|Benchmark)' | grep -v "^${skip}$" || true)
	if [[ -z "$list" ]]; then
		return
	fi
	re=$(printf '%s\n' "$list" | sed 's/[^A-Za-z0-9_]/\\&/g' | paste -sd '|' -)
	"$GO" test -mod=readonly -p 1 -count=1 -tags deadlock -run "^(${re})($|/)" "$pkg"
}

run_tests() {
	local test_args=(-mod=readonly -p 1 -count=1 -tags deadlock)
	local pkg list_file pkgs=() darwin=""
	if [[ "$(uname -s)" == Darwin ]]; then
		darwin=1
	fi
	list_file=$(mktemp)
	"$GO" list -mod=readonly \
		./crypto/... \
		./consensus/... \
		./types/... \
		./mempool/... \
		./p2p/... \
		./state/... \
		./node/... >"$list_file"
	while IFS= read -r pkg; do
		case "$pkg" in
		github.com/tendermint/tendermint/state/indexer/sink/psql)
			echo "outside release gate: ${pkg}"
			;;
		github.com/tendermint/tendermint/mempool/v0 | github.com/tendermint/tendermint/mempool/v1 | github.com/tendermint/tendermint/types)
			if [[ -n "$darwin" ]]; then
				continue
			fi
			pkgs+=("$pkg")
			;;
		*)
			pkgs+=("$pkg")
			;;
		esac
	done <"$list_file"
	rm -f "$list_file"

	if [[ ${#pkgs[@]} -gt 0 ]]; then
		"$GO" test "${test_args[@]}" "${pkgs[@]}"
	fi
	if [[ -n "$darwin" ]]; then
		echo "macOS: skipping upstream tests that fail on Darwin. Linux CI still runs them."
		run_filtered github.com/tendermint/tendermint/mempool/v0 TestBroadcastTxForPeerStopsWhenReactorStops
		run_filtered github.com/tendermint/tendermint/mempool/v1 TestTxMempool_ExpiredTxs_Timestamp
		run_filtered github.com/tendermint/tendermint/types TestPartValidateBasic
	fi
}

if [[ "${1:-}" == test ]]; then
	step "test"
	run_tests
	echo "ok"
	exit 0
fi
if [[ -n "${1:-}" ]]; then
	echo "usage: $0 [test]" >&2
	exit 1
fi

step "upstream pin"
git merge-base --is-ancestor 014cdcf09844d48f6d30f3e520034b7edffd9670 HEAD
grep -q 'TMVersionDefault = "0.34.24"' version/version.go

step "build"
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
CGO_ENABLED=0 "$GO" build -mod=readonly -trimpath -tags tendermint \
	-o "$build_dir/tendermint" ./cmd/tendermint

step "test"
run_tests

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
"$GO" mod verify
mod_dir=$(mktemp -d)
cp go.mod go.sum "$mod_dir/"
"$GO" mod tidy
if ! cmp -s go.mod "$mod_dir/go.mod" || ! cmp -s go.sum "$mod_dir/go.sum"; then
	diff -u "$mod_dir/go.mod" go.mod || true
	diff -u "$mod_dir/go.sum" go.sum || true
	cp "$mod_dir/go.mod" go.mod
	cp "$mod_dir/go.sum" go.sum
	rm -rf "$mod_dir"
	echo "${GO} mod tidy would change go.mod or go.sum" >&2
	exit 1
fi
rm -rf "$mod_dir"

step "vulnerabilities"
"$GO" run golang.org/x/vuln/cmd/govulncheck@v1.0.4 ./...

echo "ok"
