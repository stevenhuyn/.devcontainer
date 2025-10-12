FROM ubuntu:24.04

ARG USERNAME=ubuntu
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install basic dependencies
RUN apt-get update \
    && apt-get install -y \
    curl \
    build-essential \
    git \
    unzip \
    x11-apps \
    libxkbcommon-x11-0 \
    libxkbcommon-dev \
    && rm -rf /var/lib/apt/lists/*

# Install GPU/Graphics libraries
# TBH these were AI Generated so need to work out what is unecessary
RUN apt-get update \
    && apt-get install -y \
    # Mesa drivers for Intel integrated graphics
    mesa-utils \
    mesa-vulkan-drivers \
    libgl1-mesa-dri \
    libglx-mesa0 \
    libgl1 \
    libegl1 \
    # Vulkan support
    vulkan-tools \
    libvulkan1 \
    # OpenCL support (for compute)
    ocl-icd-libopencl1 \
    # Additional graphics libraries
    libglfw3 \
    libglfw3-dev \
    libglew-dev \
    && rm -rf /var/lib/apt/lists/*

# Switch to the user
USER $USERNAME

# Install Rust 
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/home/${USERNAME}/.cargo/bin:${PATH}"

# Install fnm and Node
RUN curl -fsSL https://fnm.vercel.app/install | bash
ENV PATH="/home/${USERNAME}/.local/share/fnm:${PATH}"
RUN eval "$(fnm env --shell bash)" && fnm install --lts

# Setup pnpm
ENV PNPM_HOME="/home/${USERNAME}/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN eval "$(fnm env --shell bash)" && npm install --global corepack@latest
RUN eval "$(fnm env --shell bash)" && corepack enable

# Set npm alias to pnpm
RUN echo 'alias npm="pnpm"' >> /home/${USERNAME}/.bashrc

# Install global packages via pnpm
RUN eval "$(fnm env --shell bash)" && pnpm install -g @anthropic-ai/claude-code eslint

# Install uv and Python
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && echo "export PATH=\"/home/$USERNAME/.local/bin:\$PATH\"" >> /home/$USERNAME/.bashrc

# Configure colored prompt
RUN echo 'export PS1="\[\e[32m\]\u@\h\[\e[m\]:\[\e[34m\]\w\[\e[m\]\$ "' >> /home/${USERNAME}/.bashrc

# Persist bash history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/home/${USERNAME}/.commandhistory/.bash_history" \
    && mkdir -p /home/${USERNAME}/.commandhistory \
    && touch /home/${USERNAME}/.commandhistory/.bash_history \
    && echo "$SNIPPET" >> "/home/${USERNAME}/.bashrc"

# Set working directory
WORKDIR /workspaces
USER root
RUN chown -R $USERNAME:$USERNAME /workspaces
USER $USERNAME