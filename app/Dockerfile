# ==============================================================================
# Multi-stage Dockerfile for Node.js Microservice (ECS Fargate)
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Dependencies Builder
# ------------------------------------------------------------------------------
FROM node:20-alpine AS dependencies

WORKDIR /usr/src/app

COPY package*.json ./

# Install only production dependencies
RUN npm ci --omit=dev && npm cache clean --force

# ------------------------------------------------------------------------------
# Stage 2: Final Minimal Runtime Image
# ------------------------------------------------------------------------------
FROM node:20-alpine AS runner

WORKDIR /usr/src/app

# Set production environment flags
ENV NODE_ENV=production
ENV PORT=3000

# Copy installed production node_modules from builder
COPY --from=dependencies /usr/src/app/node_modules ./node_modules
COPY package*.json ./
COPY server.js ./

# Run as non-privileged user for container security
USER node

# Expose microservice port
EXPOSE 3000

# Docker healthcheck matching ALB path
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
