# --- canary.Dockerfile (TEIL 1) ---
# Canary‑Build, kein QUIC

ARG BUILD_MODE=canary
ARG QUIC=false

FROM docker/base.Dockerfile AS base

# --- canary.Dockerfile (TEIL 2) ---
ARG UNBOUND_VERSION
ARG OPENSSL_BUILDENV_VERSION
ARG IMAGE_BUILD_DATE
ARG UNBOUND_DOCKER_IMAGE_VERSION="canary"
