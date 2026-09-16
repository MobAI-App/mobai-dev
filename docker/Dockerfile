# The mobai-dev environment: everything a coding agent needs to build iOS apps
# from Linux, installed and waiting for the app. One image for the three
# frameworks, tagged by the mobai-dev version; the toolchain versions are
# labels. Built by .github/workflows/image.yml and published as
# ghcr.io/mobai-app/mobai-dev, linux/amd64 only: the engines' Linux
# binaries and the embedded signer are x86-64.
#
# What is in it: the Swift toolchain the SwiftUI engine was built with, the
# Flutter SDK, Node, the three preview engines unpacked and bootstrapped, the
# adapters catalogue, mobai-dev with the mobai CLI and the agent skills,
# tailscale, and the system packages the paint host and Chromium need.
#
# What is not, on purpose: anything that is the user's. No account, no tailnet,
# no secrets, and no Apple design resources (SF Pro and SF Symbols): those are
# downloaded from Apple's own site on the user's sandbox at first start and
# never redistributed. Engines are installed without the verification step,
# which launches them and needs the account's grant; the first `mobai-dev
# setup` in the sandbox verifies them.
#
# Everything runs as the `ubuntu` user (uid 1000) with home /home/ubuntu, which
# is what Cursor's cloud agents and devcontainers expect. The user's repository
# is never copied in: the agent platform checks it out.

FROM ubuntu:24.04

ARG MOBAI_VERSION=1.2.0
ARG SWIFT_VERSION=6.3.3
ARG FLUTTER_VERSION=3.41.0
ARG NODE_MAJOR=20
ARG PLAYWRIGHT_VERSION=1.56.0

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC

# System packages, one layer, in three groups: what the SwiftUI engine's paint
# host and the Swift toolchain need (engines/swiftui/tool/install-host-deps.sh
# and swift.org's Ubuntu 24.04 list), what Flutter's Linux desktop build needs
# (the same list `mobai-dev setup` prescribes), and what a sandbox expects to
# find anyway.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git gnupg2 sudo unzip xz-utils zip file procps \
      python3 jq tzdata locales \
      binutils libc6-dev libcurl4-openssl-dev libedit2 libgcc-13-dev \
      libncurses-dev libpython3-dev libsqlite3-0 libstdc++-13-dev libxml2-dev \
      libz3-dev pkg-config zlib1g-dev \
      libcairo2-dev libssl-dev \
      libgtk-3-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libpangocairo-1.0-0 \
      libharfbuzz0b libatk1.0-0 libatk-bridge2.0-0 libcairo-gobject2 \
      xvfb x11-xserver-utils \
      libegl1 libgl1 libgles2 libgl1-mesa-dri libglu1-mesa \
      fonts-noto-cjk fonts-noto-color-emoji fonts-dejavu-core fonts-liberation fontconfig \
      libheif-examples librsvg2-bin p7zip-full cpio \
      cmake ninja-build libgtk-3-dev liblzma-dev \
    && rm -rf /var/lib/apt/lists/*
# No apt clang: Flutter's Linux build finds clang on PATH, and that is the
# Swift toolchain's clang 21 through swiftly's shim, which sits ahead of
# /usr/bin; apt's clang 18 and its LLVM were 340 MB that nothing ran.
# libpython3-dev stays although it only serves lldb, which is removed below:
# swiftly checks for it after installing the toolchain and fails without it.

# Node, from NodeSource as `mobai-dev setup` prescribes, and Chromium's
# runtime packages, which Playwright knows better than a hand-kept list.
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npx --yes playwright@${PLAYWRIGHT_VERSION} install-deps chromium \
    && rm -rf /var/lib/apt/lists/* /root/.npm

# The agent user: ubuntu:24.04 already carries `ubuntu` as uid 1000; give it
# passwordless sudo so `mobai-dev setup` can apt when a project needs more.
RUN id -u ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash ubuntu \
    && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu

# Flutter, the version the flutter engine's archive is built against, with the
# Linux desktop artifacts precached so the first preview does not download
# them. Owned by ubuntu: the SDK writes into its own tree.
ENV FLUTTER_ROOT=/opt/flutter \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    PUB_CACHE=/home/ubuntu/.pub-cache
RUN git clone --depth 1 --branch "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git "${FLUTTER_ROOT}" \
    && chown -R ubuntu:ubuntu "${FLUTTER_ROOT}"

USER ubuntu
WORKDIR /home/ubuntu
ENV HOME=/home/ubuntu \
    PATH=/home/ubuntu/.mobai/bin:/home/ubuntu/.local/share/swiftly/bin:/opt/flutter/bin:/home/ubuntu/.pub-cache/bin:/usr/local/bin:/usr/bin:/bin

# The profile and release engine artifacts go in the same layer they arrive
# in: the host runs in debug mode, and a delete in a later layer frees
# nothing.
RUN git config --global --add safe.directory "${FLUTTER_ROOT}" \
    && flutter config --no-analytics --enable-linux-desktop \
    && flutter precache --linux --universal \
    && flutter --version \
    && rm -rf "${FLUTTER_ROOT}"/bin/cache/artifacts/engine/linux-x64-profile \
              "${FLUTTER_ROOT}"/bin/cache/artifacts/engine/linux-x64-release

# Swift through swiftly, exactly as `mobai-dev setup` installs it, so the
# shims, the environment file and the .bashrc line are where setup and the
# engine's launcher look for them.
RUN cd /tmp && curl -fsSLO "https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz" \
    && tar zxf "swiftly-$(uname -m).tar.gz" \
    && ./swiftly init --quiet-shell-followup --assume-yes --skip-install \
    && . "$HOME/.local/share/swiftly/env.sh" \
    && swiftly install "${SWIFT_VERSION}" --use --assume-yes \
    && (grep -qs 'swiftly/env.sh' "$HOME/.bashrc" || echo '. "$HOME/.local/share/swiftly/env.sh"' >> "$HOME/.bashrc") \
    && rm -f /tmp/swiftly* \
    && swift --version \
    && T=$(ls -d "$HOME/.local/share/swiftly/toolchains/${SWIFT_VERSION}"*/usr) \
    && rm -rf "$T"/bin/lldb "$T"/bin/lldb-* "$T"/lib/liblldb* \
              "$T"/bin/sourcekit-lsp "$T"/lib/libsourcekitdInProc.so \
              "$T"/bin/docc "$T"/bin/swift-format "$T"/bin/clangd \
              "$T"/lib/swift_static "$T"/lib/swift/embedded \
              "$T"/bin/swift-build-sdk-interfaces

# mobai-dev, the mobai CLI, the agent skills, tailscale and mobai-up, through
# the same script every sandbox runs. The script refreshes the binary from the
# published manifest, so a sandbox built from an older image still ends up on
# the current build at its own install step.
RUN curl -fsSL "https://raw.githubusercontent.com/MobAI-App/mobai-dev/main/scripts/install.sh" | sh \
    && mobai-dev version

# The three preview engines from the release, unpacked and bootstrapped, no
# verification (that needs the user's account) and no Apple fonts (those are
# the user's to download). Host packages are already above, so bootstrap does
# not apt.
ENV MOBAI_SKIP_HOST_DEPS=1
RUN mkdir -p /tmp/engines && cd /tmp/engines \
    && for e in swiftui-linux-x64 flutter-linux-x64 rn; do \
         curl -fsSL -O "https://github.com/MobAI-App/mobai-dev/releases/download/v${MOBAI_VERSION}/${e}.tar.gz"; \
         curl -fsSL -O "https://github.com/MobAI-App/mobai-dev/releases/download/v${MOBAI_VERSION}/${e}.tar.gz.sha256"; \
         sha256sum -c "${e}.tar.gz.sha256"; \
       done \
    && MOBAI_SKIP_SF_PRO=1 MOBAI_SKIP_SF_SYMBOLS=1 mobai-dev engines install swiftui --from swiftui-linux-x64.tar.gz --skip-verify --json \
    && mobai-dev engines install flutter --from flutter-linux-x64.tar.gz --skip-verify --json \
    && mobai-dev engines install rn --from rn.tar.gz --skip-verify --json \
    && mobai-dev adapters update --json \
    && cd / && rm -rf /tmp/engines /home/ubuntu/.npm /home/ubuntu/.cache/pip \
              "$HOME"/.cache/ms-playwright/chromium-* "$HOME"/.cache/ms-playwright/ffmpeg-*

# On the deletions above, about 2.4 GB between them, each in the layer that
# produced the files because a later layer's delete frees nothing: the Swift
# toolchain ships a debugger, a language server, a documentation compiler, a
# formatter and the Embedded Swift standard library that no preview ever
# uses, and a static standard library the engine never links; Playwright
# installs a full Chromium beside the headless shell, and the RN engine
# launches headless, which is the shell; Flutter's profile and release engine
# artifacts serve builds the preview never makes. Each was removed and the
# engines verified afterwards.

LABEL org.opencontainers.image.title="mobai-dev" \
      org.opencontainers.image.description="Everything a coding agent needs to build iOS apps from a Linux sandbox: SwiftUI, Flutter and React Native previews, CI builds, simulators and a real iPhone." \
      org.opencontainers.image.source="https://github.com/MobAI-App/mobai-dev" \
      org.opencontainers.image.version="${MOBAI_VERSION}" \
      org.opencontainers.image.licenses="MIT" \
      run.mobai.mobai-dev="${MOBAI_VERSION}" \
      run.mobai.swift="${SWIFT_VERSION}" \
      run.mobai.flutter="${FLUTTER_VERSION}" \
      run.mobai.node="${NODE_MAJOR}"

CMD ["/bin/bash"]
