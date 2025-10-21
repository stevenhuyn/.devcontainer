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
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Switch to the user
USER $USERNAME

# Install mise
RUN curl https://mise.run | sh

# Add mise to PATH and enable mise activation
ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"
RUN echo 'eval "$(mise activate bash)"' >> /home/${USERNAME}/.bashrc

# Configure mise to install tools
RUN mise use --global pnpm@latest && \
    mise use --global rust@latest && \
    mise use --global go@latest && \
    mise use --global uv@latest
a
# Install the tools via mise
RUN mise install

# Verify installations
RUN \
    mise exec -- pnpm --version && \
    echo 'alias npm="pnpm"' >> /home/${USERNAME}/.bashrc \
    mise exec -- rustc --version && \
    mise exec -- go version && \
    mise exec -- uv --version

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