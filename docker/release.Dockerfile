# --- release.Dockerfile (TEIL 1) ---
# Release‑Build, kein QUIC

ARG BUILD_MODE=release
ARG QUIC=false

FROM base AS base

# --- release.Dockerfile (TEIL 2) ---
# Release‑spezifische Build‑Args

ARG UNBOUND_VERSION
ARG UNBOUND_SHA256
ARG OPENSSL_BUILDENV_VERSION
ARG IMAGE_BUILD_DATE
ARG UNBOUND_DOCKER_IMAGE_VERSION
