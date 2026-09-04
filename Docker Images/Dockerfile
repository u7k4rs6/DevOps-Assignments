# ==========================================================
# Stage 1: builder
# Installs EVERY dependency (production + dev: eslint, jest)
# and brings in the full source tree. Nothing from this stage
# survives into the final image unless it is explicitly copied.
# ==========================================================
FROM node:20-alpine AS builder

WORKDIR /app

# Manifests first so this layer stays cached until deps actually change
COPY package*.json ./
RUN npm install

# Full source (dev deps, tests, configs - all of it)
COPY . .

# ==========================================================
# Stage 2: production
# Starts again from a clean base and copies ONLY what is
# needed to run. No dev dependencies, no build tooling,
# no npm cache, no source history.
# ==========================================================
FROM node:20-alpine AS production

WORKDIR /app

# Manifests come from the builder stage, not the host
COPY --from=builder /app/package*.json ./

# Production dependencies only, then throw the cache away
RUN npm install --omit=dev && npm cache clean --force

# Just the one file the app actually needs to run
COPY --from=builder /app/server.js ./

EXPOSE 8080
CMD ["npm", "start"]
