# --- release_quic.Dockerfile (TEIL 1) ---
# Release‑Build, QUIC aktiviert

ARG BUILD_MODE=release
ARG QUIC=true

FROM docker/base.Dockerfile AS base

# --- release_quic.Dockerfile (TEIL 2) ---
ARG UNBOUND_VERSION
ARG UNBOUND_SHA256
ARG OPENSSL_QUIC_BUILDENV_VERSION
ARG IMAGE_BUILD_DATE
ARG UNBOUND_DOCKER_IMAGE_VERSION
