FROM node:25.2.1-alpine3.21

WORKDIR /app

# Ensure package index is fresh and upgrade busybox (robust) or try pin (fallback)
RUN apk update \
  && (apk add --no-cache busybox=1.37.0-r14 || apk upgrade busybox) \
  && apk --no-cache add ca-certificates

# Copy package files first to leverage Docker layer cache
COPY package*.json ./

# Use npm ci for deterministic installs (falls back to npm install if lockfile missing)
RUN if [ -f package-lock.json ]; then npm ci --only=production; else npm install --production; fi

# Copy app sources (after deps)
COPY . .

# Optional: create non-root user and drop privileges
RUN addgroup -S appgroup && adduser -S appuser -G appgroup \
  && chown -R appuser:appgroup /app
USER appuser

EXPOSE 8080
CMD ["node", "index.js"]
