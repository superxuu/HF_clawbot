# Use Node.js 22 as the base image
FROM node:22-bullseye

# Install corepack for pnpm support
RUN corepack enable && corepack prepare pnpm@latest --activate

# Set working directory
WORKDIR /app

# Copy dependency definitions
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
# Copy patches if they exist (ignoring if not present effectively, but COPY fails if not found unless we use wildcard)
# We know patches dir exists from `list_dir`
COPY patches ./patches

# Install dependencies (frozen lockfile for reproducibility)
RUN pnpm install --frozen-lockfile

# Copy the rest of the application source code
COPY . .

# Build the project
# This includes compiling TypeScript and other assets
RUN pnpm build

# Build the UI
# This ensures the frontend assets are available
RUN pnpm ui:build

# Fix permissions for the node user
RUN chown -R node:node /app

# Switch to non-root user for security
USER node

# Expose the port (7860 is standard for HF Spaces)
EXPOSE 7860

# Set environment variables
ENV NODE_ENV=production
# Default port if not provided by HF
ENV PORT=7860

# Start the application
# We use shell form to ensure the PORT environment variable is correctly mapped 
# to OPENCLAW_GATEWAY_PORT, which the application uses.
CMD ["sh", "-c", "export OPENCLAW_GATEWAY_PORT=${PORT:-7860}; node scripts/run-node.mjs"]
