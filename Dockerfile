# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ARG GO_VERSION=1.26.1
ARG NVIM_VERSION=v0.12.1
ARG ZOXIDE_VERSION=0.9.9
ARG JUST_VERSION=1.49.0
ARG GRPCURL_VERSION=1.9.3
ARG USQL_VERSION=0.21.4
# Automatically set by BuildKit; declare here to make it available in RUN steps.
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Global install paths for user-space language toolchains
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    BUN_INSTALL=/usr/local/bun

ENV PATH=/usr/local/go/bin:/usr/local/cargo/bin:/usr/local/bun/bin:/opt/nvim/bin:${PATH}

# ── System packages ────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        zsh \
        tmux \
        jq \
        fzf \
        btop \
        curl \
        wget \
        httpie \
        git \
        build-essential \
        ca-certificates \
        locales \
        ripgrep \
        fd-find \
        bat \
        zsh-syntax-highlighting \
        python3 \
        python3-pip \
        python3-venv \
        unzip \
        bzip2 \
        xz-utils \
        sudo \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    # fd-find installs as fdfind; bat installs as batcat – create canonical names
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat \
    && rm -rf /var/lib/apt/lists/*

# ── Go ─────────────────────────────────────────────────────────────────────────
RUN case "$TARGETARCH" in \
      amd64) GOARCH=amd64 ;; \
      arm64) GOARCH=arm64 ;; \
      *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GOARCH}.tar.gz" \
    | tar -C /usr/local -xz

# ── Rust ───────────────────────────────────────────────────────────────────────
RUN curl -fsSL https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path --default-toolchain stable \
    && chmod -R a+w "$RUSTUP_HOME" "$CARGO_HOME"

# ── uv (Python toolchain manager) ─────────────────────────────────────────────
RUN curl -LsSf https://astral.sh/uv/install.sh -o /tmp/uv-install.sh \
    && UV_INSTALL_DIR=/usr/local/bin sh /tmp/uv-install.sh \
    && rm /tmp/uv-install.sh

# ── Bun ────────────────────────────────────────────────────────────────────────
RUN curl -fsSL https://bun.sh/install | bash \
    && chmod -R a+rx "$BUN_INSTALL"

# ── Neovim ─────────────────────────────────────────────────────────────────────
RUN case "$TARGETARCH" in \
      amd64) NVIM_ARCH=x86_64 ;; \
      arm64) NVIM_ARCH=arm64  ;; \
      *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac \
    && curl -fsSL \
      "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-${NVIM_ARCH}.tar.gz" \
    | tar -C /opt -xz \
    && mv "/opt/nvim-linux-${NVIM_ARCH}" /opt/nvim

# ── Zoxide ─────────────────────────────────────────────────────────────────────
RUN case "$TARGETARCH" in \
      amd64) ZOXIDE_ARCH=x86_64-unknown-linux-musl   ;; \
      arm64) ZOXIDE_ARCH=aarch64-unknown-linux-musl  ;; \
      *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac \
    && curl -fsSL \
      "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-${ZOXIDE_ARCH}.tar.gz" \
    | tar -C /usr/local/bin -xz zoxide

# ── just (command runner) ──────────────────────────────────────────────────────
RUN case "$TARGETARCH" in \
      amd64) JUST_ARCH=x86_64-unknown-linux-musl   ;; \
      arm64) JUST_ARCH=aarch64-unknown-linux-musl  ;; \
      *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac \
    && curl -fsSL \
      "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-${JUST_ARCH}.tar.gz" \
    | tar -xzf - -C /usr/local/bin just

# ── grpcurl (gRPC CLI) ─────────────────────────────────────────────────────────
RUN case "$TARGETARCH" in \
      amd64) GRPCURL_ARCH=x86_64 ;; \
      arm64) GRPCURL_ARCH=arm64  ;; \
      *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac \
    && curl -fsSL \
      "https://github.com/fullstorydev/grpcurl/releases/download/v${GRPCURL_VERSION}/grpcurl_${GRPCURL_VERSION}_linux_${GRPCURL_ARCH}.tar.gz" \
    | tar -xzf - -C /usr/local/bin grpcurl

# ── usql (universal SQL client) ────────────────────────────────────────────────
RUN case "$TARGETARCH" in \
      amd64) USQL_ARCH=amd64 ;; \
      arm64) USQL_ARCH=arm64 ;; \
      *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac \
    && curl -fsSL \
      "https://github.com/xo/usql/releases/download/v${USQL_VERSION}/usql_static-${USQL_VERSION}-linux-${USQL_ARCH}.tar.bz2" \
    | tar -xjf - -C /usr/local/bin usql_static \
    && mv /usr/local/bin/usql_static /usr/local/bin/usql

# ── AWS CLI v2 ─────────────────────────────────────────────────────────────────
RUN case "$TARGETARCH" in \
      amd64) AWSCLI_ARCH=x86_64 ;; \
      arm64) AWSCLI_ARCH=aarch64 ;; \
      *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac \
    && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLI_ARCH}.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/awscliv2.zip /tmp/aws

# ── dev user ───────────────────────────────────────────────────────────────────
# Ubuntu 24.04 ships with a built-in `ubuntu` user at uid/gid 1000.
# Rename it to `dev` and relocate its home rather than creating a duplicate.
RUN usermod  -l dev -d /home/dev -m ubuntu \
    && groupmod -n dev ubuntu \
    && usermod  -s /bin/zsh dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev \
    && chmod 440 /etc/sudoers.d/dev \
    # hand ownership of the mutable toolchain dirs to dev so they can
    # run `rustup update`, `cargo install`, `bun upgrade`, etc.
    && chown -R dev:dev "$RUSTUP_HOME" "$CARGO_HOME" "$BUN_INSTALL"

# ── Oh My Zsh + shell config ───────────────────────────────────────────────────
USER dev
ENV HOME=/home/dev
WORKDIR /home/dev

RUN sh -c "$(curl -fsSL \
    https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended

# zsh-autosuggestions as an oh-my-zsh custom plugin
RUN git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
    /home/dev/.oh-my-zsh/custom/plugins/zsh-autosuggestions

COPY --chown=dev:dev config/kardan.zsh-theme /home/dev/.oh-my-zsh/themes/kardan.zsh-theme
COPY --chown=dev:dev config/zshrc /home/dev/.zshrc

# ── Smoke-test script ──────────────────────────────────────────────────────────
USER root
COPY scripts/test.sh /usr/local/bin/test-devcontainer
RUN chmod +x /usr/local/bin/test-devcontainer

SHELL ["/bin/zsh", "-c"]
USER dev
WORKDIR /home/dev
CMD ["zsh"]
