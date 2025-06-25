# Use a specific Node.js version for better reproducibility
FROM node:23.3.0-slim AS builder

# Install pnpm globally and necessary build tools
RUN npm install -g pnpm@9.15.4 && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    git \
    python3 \
    python3-pip \
    curl \
    node-gyp \
    ffmpeg \
    libtool-bin \
    autoconf \
    automake \
    libopus-dev \
    make \
    g++ \
    build-essential \
    libcairo2-dev \
    libjpeg-dev \
    libpango1.0-dev \
    libgif-dev \
    openssl \
    libssl-dev libsecret-1-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set Python 3 as the default python
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Set the working directory
WORKDIR /app

# Copy application code
COPY . .

# Install dependencies
RUN pnpm install

# Install clients and plugins we expose to users
WORKDIR /app/packages/cli
RUN --mount=type=secret,id=GIT_USERNAME,env=GIT_USERNAME --mount=type=secret,id=GIT_PASSWORD,env=GIT_PASSWORD node index.js plugins install @elizaos-plugins/plugin-0g && \
    node index.js plugins install @elizaos-plugins/plugin-abstract && \
    node index.js plugins install @elizaos-plugins/plugin-akash && \
    node index.js plugins install @elizaos-plugins/plugin-allora && \
    node index.js plugins install @elizaos-plugins/plugin-anyone && \
    node index.js plugins install @elizaos-plugins/plugin-aptos && \
    node index.js plugins install @elizaos-plugins/plugin-arthera && \
    node index.js plugins install @elizaos-plugins/plugin-asterai && \
    node index.js plugins install @elizaos-plugins/plugin-autonome && \
    node index.js plugins install @elizaos-plugins/plugin-avail && \
    node index.js plugins install @elizaos-plugins/plugin-avalanche && \
    node index.js plugins install @elizaos-plugins/plugin-binance && \
    node index.js plugins install @elizaos-plugins/plugin-coingecko && \
    node index.js plugins install @elizaos-plugins/plugin-coinmarketcap && \
    node index.js plugins install @elizaos-plugins/plugin-conflux && \
    node index.js plugins install @elizaos-plugins/plugin-cosmos && \
    node index.js plugins install @elizaos-plugins/plugin-cronoszkevm && \
    node index.js plugins install @elizaos-plugins/plugin-depin && \
    node index.js plugins install @elizaos-plugins/plugin-evm && \
    node index.js plugins install @elizaos-plugins/plugin-flow && \
    node index.js plugins install @elizaos-plugins/plugin-fuel && \
    node index.js plugins install @elizaos-plugins/plugin-genlayer && \
    node index.js plugins install @elizaos-plugins/plugin-hyperliquid && \
    node index.js plugins install @elizaos-plugins/plugin-icp && \
    node index.js plugins install @elizaos-plugins/plugin-multiversx && \
    node index.js plugins install @elizaos-plugins/plugin-near && \
    node index.js plugins install @elizaos-plugins/plugin-rabbi-trader && \
    node index.js plugins install @elizaos-plugins/plugin-solana && \
    node index.js plugins install @elizaos-plugins/plugin-spheron && \
    node index.js plugins install @elizaos-plugins/plugin-starknet && \
    node index.js plugins install @elizaos-plugins/plugin-sui && \
    node index.js plugins install @elizaos-plugins/plugin-ton && \
    node index.js plugins install @elizaos-plugins/client-discord && \
    node index.js plugins install @elizaos-plugins/client-twitter && \
    node index.js plugins install @elizaos-plugins/client-telegram && \
    node index.js plugins install @elizaos-plugins/client-direct && \
    node index.js plugins install @elizaos-plugins/client-farcaster && \
    node index.js plugins install @elizaos-plugins/client-lens && \
    node index.js plugins install @elizaos-plugins/client-slack && \
    node index.js plugins install @elizaos-plugins/client-github
WORKDIR /app

# Build the project
RUN pnpm run build && pnpm prune --prod

# Final runtime image
FROM node:23.3.0-slim

# Install runtime dependencies
RUN npm install -g pnpm@9.15.4 && \
    apt-get update && \
    apt-get install -y \
    git \
    python3 \
    ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy built artifacts and production dependencies from the builder stage
COPY --from=builder /app/package.json ./
COPY --from=builder /app/pnpm-workspace.yaml ./
COPY --from=builder /app/.npmrc ./
COPY --from=builder /app/turbo.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/agent ./agent
COPY --from=builder /app/client ./client
COPY --from=builder /app/lerna.json ./
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/characters ./characters

# Expose necessary ports
EXPOSE 3000 5173

# Command to start the application
CMD ["sh", "-c", "pnpm start & pnpm start:client"]
