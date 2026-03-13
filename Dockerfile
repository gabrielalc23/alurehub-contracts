# syntax=docker/dockerfile:1.7

ARG BASE_IMAGE=ubuntu:24.04
ARG SOLC_IMAGE=ethereum/solc:0.8.34
ARG OPENZEPPELIN_VERSION=v5.5.0
ARG FORGE_STD_VERSION=v1.12.0
ARG FOUNDRY_VERSION=v1.5.0

FROM alpine/git:2.47.2 AS deps
ARG OPENZEPPELIN_VERSION
ARG FORGE_STD_VERSION
WORKDIR /deps
RUN git clone --depth 1 --branch "${OPENZEPPELIN_VERSION}" https://github.com/OpenZeppelin/openzeppelin-contracts.git openzeppelin-contracts \
    && git clone --depth 1 --branch "${FORGE_STD_VERSION}" https://github.com/foundry-rs/forge-std.git forge-std

FROM ${SOLC_IMAGE} AS solc

FROM ${BASE_IMAGE} AS app
ARG FOUNDRY_VERSION

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl git xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup --install "${FOUNDRY_VERSION}"

WORKDIR /app

COPY --from=solc /usr/bin/solc /usr/bin/solc
COPY --from=deps /deps/openzeppelin-contracts /app/lib/openzeppelin-contracts
COPY --from=deps /deps/forge-std /app/lib/forge-std

COPY foundry.toml ./
COPY script ./script
COPY src ./src
COPY test ./test

RUN forge --version \
    && solc --version \
    && forge fmt --check \
    && forge build

ENTRYPOINT ["forge"]
CMD ["test"]
