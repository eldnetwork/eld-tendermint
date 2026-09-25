# Pinned golang:1.18.10-alpine (index digest). Same image as golang:1.18-alpine.
FROM golang@sha256:77f25981bd57e60a510165f3be89c901aec90453fd0f1c5a45691f6cb1528807 AS build

WORKDIR /src
COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -mod=readonly \
    -trimpath \
    -tags tendermint \
    -ldflags "-X github.com/tendermint/tendermint/version.TMCoreSemVer=v0.34.24 -s -w" \
    -o /out/tendermint \
    ./cmd/tendermint

# Pinned alpine:3.20 (index digest).
FROM alpine@sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc

RUN apk add --no-cache ca-certificates bash curl \
    && addgroup -g 1000 tmuser \
    && adduser -D -s /bin/bash -u 1000 -G tmuser tmuser \
    && mkdir -p /tendermint/.tendermint/config /tendermint/.tendermint/data \
    && chown -R tmuser:tmuser /tendermint

COPY --from=build /out/tendermint /usr/local/bin/tendermint
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/tendermint /usr/local/bin/docker-entrypoint.sh

USER tmuser
WORKDIR /tendermint

EXPOSE 26656 26657 26660
ENV TMHOME=/tendermint/.tendermint

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["tendermint", "node"]
