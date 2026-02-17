FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_COMPILE_BYTECODE=1

# Install Node.js 20 and system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates gnupg git && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get purge -y gnupg && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN groupadd -r nanouser && useradd -r -g nanouser -d /app nanouser
WORKDIR /app

# Install Python dependencies (Cached)
COPY pyproject.toml README.md LICENSE ./
RUN mkdir -p nanobot bridge && touch nanobot/__init__.py && \
    uv pip install --system --no-cache .

# Copy full source and install project
COPY nanobot/ nanobot/
COPY bridge/ bridge/
RUN uv pip install --system --no-cache .

# Build the WhatsApp bridge
WORKDIR /app/bridge
RUN npm install && npm run build
WORKDIR /app

# Set up config directory permissions
RUN mkdir -p /app/.nanobot && chown -R nanouser:nanouser /app
ENV NANOBOT_CONFIG_DIR=/app/.nanobot

# Use the non-root user
USER nanouser

EXPOSE 18790

ENTRYPOINT ["nanobot"]
CMD ["status"]
