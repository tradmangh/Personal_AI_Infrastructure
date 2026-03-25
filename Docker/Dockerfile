# --- Build Stage ---
FROM node:20-bookworm-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash

# --- Final Stage ---
FROM node:20-bookworm-slim

# Install runtime dependencies
# We use a cleaner run command to avoid metadata overhead issues in some CI environments
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    git \
    bash \
    ca-certificates \
    sudo \
    unzip \
    python3 \
    mpg123 \
    ttyd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy Bun from builder
COPY --from=builder /root/.bun /home/pai/.bun
ENV PATH="/home/pai/.bun/bin:${PATH}"

# Create user 'pai'
RUN useradd -m -s /bin/bash pai && \
    echo "pai ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create app directory
RUN mkdir -p /usr/local/pai && chown pai:pai /usr/local/pai

USER pai
WORKDIR /home/pai

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Copy PAI release files to /usr/local/pai
COPY --chown=pai:pai Releases/v4.0.3/.claude /usr/local/pai

# Copy the startup script
COPY --chown=pai:pai Docker/startup.sh /home/pai/startup.sh
RUN chmod +x /home/pai/startup.sh

# Expose ports
EXPOSE 8080 8888

# Persistence
VOLUME [ "/home/pai/.claude/MEMORY", "/home/pai/.claude/USER", "/home/pai/.config/PAI" ]

# Entrypoint
ENTRYPOINT ["/home/pai/startup.sh"]
