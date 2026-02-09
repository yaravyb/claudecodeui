# Stage 1: Install ALL dependencies (dev + prod) with build tools for native modules
FROM node:20-bookworm AS deps

RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

# Stage 2: Build the frontend with Vite
FROM deps AS build

COPY . .
RUN npm run build

# Stage 3: Production image
FROM node:20-bookworm-slim AS production

# Install runtime dependencies and build tools needed for native modules
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

WORKDIR /app

# Copy package files and install production-only dependencies
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copy built frontend from build stage
COPY --from=build /app/dist ./dist

# Copy server and shared code
COPY server/ ./server/
COPY shared/ ./shared/

# Copy public assets if they exist
COPY public/ ./public/

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create data directory for SQLite database and set ownership
# Use the built-in 'node' user (UID 1000) from the base image
RUN mkdir -p /data && chown node:node /data
RUN chown -R node:node /app

USER node

# Default environment variables
ENV NODE_ENV=production
ENV PORT=3001
ENV DATABASE_PATH=/data/auth.db

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD node -e "fetch('http://localhost:3001/health').then(r => { if (!r.ok) process.exit(1) }).catch(() => process.exit(1))"

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "server/index.js"]
