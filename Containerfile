# SPDX-FileCopyrightText: Fedora Atomic Desktops maintainers
# SPDX-License-Identifier: MIT

ARG BASEIMAGE_REPOSITORY=overridden
ARG BASEIMAGE_TAG=overridden

ARG COSIGN_REPOSITORY=overridden
ARG COSIGN_TAG=overridden

ARG CHUNKAH_REPOSITORY=overridden
ARG CHUNKAH_TAG=overridden

ARG NODEJS_VERSION=overridden

FROM ${COSIGN_REPOSITORY}:${COSIGN_TAG} AS cosign-bin

FROM ${BASEIMAGE_REPOSITORY}:${BASEIMAGE_TAG} AS builder

COPY --from=cosign-bin /ko-app/cosign /usr/bin/cosign

ENV NODEJS_VERSION=${NODEJS_VERSION}

# Install the required packages
RUN --mount=type=cache,rw,target=/cache \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    <<EORUN

    set -euo pipefail
    set -x
    export FORCE_COLUMNS=134

    rm --force /etc/yum.repos.d/fedora-cisco-openh264.repo
    dnf upgrade --assumeyes --refresh --no-allow-downgrade \
        --allowerasing

    dnf --assumeyes --refresh install --allowerasing \
        --no-allow-downgrade --no-docs --setopt=tsflags=nodocs \
        --setopt=install_weak_deps=False --best \
            nodejs${NODEJS_VERSION} \
            podman \
            buildah \
            skopeo \
            distribution-gpg-keys \
            dbus-daemon \
            file \
            git-core \
            jq \
            just \
            ostree \
            rpm-ostree \
            python3-pyyaml \
            selinux-policy-targeted \
            tar \
            zstd
    dnf clean all
    rm --recursive --force /tmp/* /var/lib/dnf/* /var/cache/dnf/* /var/log/*
EORUN

# # Rechunk
# FROM ${CHUNKAH_REPOSITORY}:${CHUNKAH_TAG} AS chunkah

# RUN --mount=from=builder,src=/,target=/chunkah,ro \
#     --mount=type=bind,target=/run/src,rw \
#         chunkah build > /run/src/buildroot.ociarchive

# # Final image
# FROM oci-archive:buildroot.ociarchive
