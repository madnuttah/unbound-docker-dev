FROM scratch as fuckyou

ARG BUILD_MODE=release        # release | canary
ARG QUIC=false               # true | false

ARG IMAGE_BUILD_DATE
ARG UNBOUND_VERSION
ARG UNBOUND_SHA256
ARG UNBOUND_UID="1000"
ARG UNBOUND_GID="1000"
ARG OPENSSL_BUILDENV_VERSION
ARG OPENSSL_QUIC_BUILDENV_VERSION

# --- Buildenv auswählen ---
# QUIC=true  → openssl-quic-buildenv
# QUIC=false → openssl-buildenv
FROM madnuttah/openssl-buildenv:${QUIC == "true" ? OPENSSL_QUIC_BUILDENV_VERSION : OPENSSL_BUILDENV_VERSION} AS buildenv

ARG BUILD_MODE \
    UNBOUND_VERSION \
    UNBOUND_SHA256 \
    UNBOUND_UID \
    UNBOUND_GID

ENV UNBOUND_VERSION="${UNBOUND_VERSION}" \
    UNBOUND_SHA256="${UNBOUND_SHA256}" \
    UNBOUND_UID="${UNBOUND_UID}" \
    UNBOUND_GID="${UNBOUND_GID}" \
    INTERNIC_PGP="F0CB1A326BDF3F3EFA3A01FA937BB869E3A238C5"

WORKDIR /tmp/src

# --- User + Build Dependencies ---
RUN set -xe; \
    addgroup -S -g "${UNBOUND_GID}" _unbound && \
    adduser -S -H -h /usr/local/unbound -g _unbound -u "${UNBOUND_UID}" -D -G _unbound _unbound && \
    apk --no-cache add ca-certificates gnupg curl file binutils && \
    apk --no-cache add --virtual .build-deps \
        build-base libsodium-dev linux-headers nghttp2-dev libevent-dev \
        expat-dev protobuf-c-dev hiredis-dev apk-tools

# --- Unbound Quelle auswählen ---
# Release → Tarball + SHA256 + PGP
# Canary  → Git HEAD
RUN if [ "$BUILD_MODE" = "release" ]; then \
        curl -sSL "https://www.nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz" -o unbound.tar.gz && \
        curl -sSL "https://www.nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz.asc" -o unbound.tar.gz.asc && \
        echo "${UNBOUND_SHA256} *unbound.tar.gz" | sha256sum -c - && \
        GNUPGHOME="$(mktemp -d)" && \
        curl -sSL https://nlnetlabs.nl/downloads/keys/releases-g2.asc -o "${GNUPGHOME}/releases-g2.asc" && \
        gpg --import "${GNUPGHOME}/releases-g2.asc" && \
        gpg --batch --verify unbound.tar.gz.asc unbound.tar.gz && \
        tar -xzf unbound.tar.gz && \
        mv "unbound-${UNBOUND_VERSION}" unbound-src; \
    else \
        git clone https://github.com/NLnetLabs/unbound unbound-src; \
    fi

# --- Configure Flags dynamisch erweitern ---
# QUIC=true → ngtcp2 aktivieren
RUN CONFIGURE_FLAGS=""; \
    if [ "$QUIC" = "true" ]; then \
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --with-libngtcp2=/usr/local/ngtcp2"; \
    fi; \
    cd unbound-src && \
    ./configure \
        --prefix=/usr/local/unbound/unbound.d \
        --with-run-dir=/usr/local/unbound/unbound.d \
        --with-conf-file=/usr/local/unbound/unbound.conf \
        --with-pidfile=/usr/local/unbound/unbound.d/unbound.pid \
        --mandir=/usr/share/man \
        --with-rootkey-file=/usr/local/unbound/iana.d/root.key \
        --with-ssl=/usr/local/openssl \
        --with-libevent \
        --with-libnghttp2 \
        --with-libhiredis \
        $CONFIGURE_FLAGS \
        --disable-shared \
        --enable-dnstap \
        --enable-dnscrypt \
        --enable-cachedb \
        --enable-subnet \
        --with-pthreads \
        --without-pythonmodule \
        --without-pyunbound \
        --enable-event-api \
        --enable-tfo-server \
        --enable-tfo-client \
        --enable-pie \
        --enable-relro-now && \
    make -j"$(nproc)" && \
    make install
# --- BASE DOCKERFILE (TEIL 2) ---
# Dies ist der zweite Teil der Base-Architektur

# --- Root Hints + Root Zone + GPG Verification ---
# (identisch für Release & Canary, QUIC & non‑QUIC)

RUN set -xe; \
    mkdir -p "/usr/local/unbound/iana.d/" && \
    curl -sSL https://www.internic.net/domain/named.cache -o /usr/local/unbound/iana.d/root.hints && \
    curl -sSL https://www.internic.net/domain/named.cache.md5 -o /usr/local/unbound/iana.d/root.hints.md5 && \
    curl -sSL https://www.internic.net/domain/named.cache.sig -o /usr/local/unbound/iana.d/root.hints.sig && \
    ROOT_HINTS_MD5="$(cat /usr/local/unbound/iana.d/root.hints.md5)" && \
    echo "${ROOT_HINTS_MD5} */usr/local/unbound/iana.d/root.hints" | md5sum -c - && \
    curl -sSL https://www.internic.net/domain/root.zone -o /usr/local/unbound/iana.d/root.zone && \
    curl -sSL https://www.internic.net/domain/root.zone.md5 -o /usr/local/unbound/iana.d/root.zone.md5 && \
    curl -sSL https://www.internic.net/domain/root.zone.sig -o /usr/local/unbound/iana.d/root.zone.sig && \
    ROOT_ZONE_MD5="$(cat /usr/local/unbound/iana.d/root.zone.md5)" && \
    echo "${ROOT_ZONE_MD5} */usr/local/unbound/iana.d/root.zone" | md5sum -c - && \
    GNUPGHOME="$(mktemp -d)" && \
    gpg --no-tty --keyserver hkps://keys.openpgp.org --recv-keys "$INTERNIC_PGP" && \
    gpg --verify /usr/local/unbound/iana.d/root.hints.sig /usr/local/unbound/iana.d/root.hints && \
    gpg --verify /usr/local/unbound/iana.d/root.zone.sig /usr/local/unbound/iana.d/root.zone && \
    /usr/local/unbound/sbin/unbound-anchor -v -a /usr/local/unbound/iana.d/root.key || true

# --- Distroless Stage ---
FROM scratch AS stage

COPY --from=buildenv /usr/local/unbound/ /app/usr/local/unbound/
COPY --from=buildenv /lib/*-musl-* /app/lib/
COPY --from=buildenv /bin/sh /bin/sed /bin/grep /bin/netstat /bin/chown /bin/chgrp /app/bin/
COPY --from=buildenv /sbin/su-exec /sbin/tini /app/sbin/
COPY --from=buildenv /usr/sbin/groupmod /usr/sbin/usermod /app/usr/sbin/
COPY --from=buildenv /usr/bin/awk /usr/bin/drill /usr/bin/id /app/usr/bin/

# OpenSSL libs
COPY --from=buildenv /usr/local/openssl/lib/libssl.so.* /usr/local/openssl/lib/libcrypto.so.* /app/lib/

# QUIC libs (nur wenn QUIC=true)
COPY --from=buildenv /usr/local/ngtcp2/lib/lib*.so.* /app/lib/

# System libs
COPY --from=buildenv /usr/lib/libgcc_s* \
                     /usr/lib/libbsd* \
                     /usr/lib/libmd* \
                     /usr/lib/libsodium* \
                     /usr/lib/libexpat* \
                     /usr/lib/libprotobuf-c* \
                     /usr/lib/libnghttp2* \
                     /usr/lib/libldns* \
                     /usr/lib/libhiredis* \
                     /usr/lib/libevent* \
                     /app/usr/lib/

COPY --from=buildenv /etc/ssl/ /app/etc/ssl/
COPY --from=buildenv /etc/passwd /etc/group /app/etc/
COPY --from=buildenv /usr/share/zoneinfo/ /app/usr/share/zoneinfo/
COPY --from=buildenv --chmod=0755 /entrypoint /app/

WORKDIR /

# --- Final Stage ---
FROM scratch AS unbound

ARG IMAGE_BUILD_DATE
ARG UNBOUND_VERSION
ARG UNBOUND_DOCKER_IMAGE_VERSION
ARG QUIC
ARG UNBOUND_UID

ENV IMAGE_BUILD_DATE="${IMAGE_BUILD_DATE}" \
    UNBOUND_VERSION="${UNBOUND_VERSION}" \
    UNBOUND_DOCKER_IMAGE_VERSION="${UNBOUND_DOCKER_IMAGE_VERSION}" \
    UNBOUND_UID="${UNBOUND_UID}" \
    PATH=/usr/local/unbound/unbound.d/sbin:"$PATH"

LABEL org.opencontainers.image.title="madnuttah/unbound" \
      org.opencontainers.image.created="${IMAGE_BUILD_DATE}" \
      org.opencontainers.image.version="${UNBOUND_DOCKER_IMAGE_VERSION}" \
      org.opencontainers.image.description="Unbound is a validating, recursive, and caching DNS resolver." \
      org.opencontainers.image.summary="Distroless Unbound image with security, performance and minimal footprint." \
      org.opencontainers.image.source="https://github.com/madnuttah/unbound-docker" \
      org.opencontainers.image.authors="madnuttah" \
      org.opencontainers.image.licenses="MIT"

COPY --from=stage /app/ /

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint"]
