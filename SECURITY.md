# Security

## Eld packaging

Report vulnerabilities in the Eld image, Dockerfile, or this repository's packaging through GitHub Security Advisories on [eldnetwork/eld-tendermint](https://github.com/eldnetwork/eld-tendermint) or [eldnetwork/eld-chain](https://github.com/eldnetwork/eld-chain).

Do not open a public issue for key material, validator keys, or node keys.

Protocol and application bugs in eld-chain belong on eld-chain, not here.

## Unmodified Tendermint

This repository vendors Tendermint Core v0.34.24 without Go patches. A consensus bug in that upstream code is an upstream 0.34 issue. Eld may not patch it.

This repository does not run a bug bounty. The upstream Tendermint / Cosmos bounty does not cover Eld.
