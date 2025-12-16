FROM node:25.2.1-alpine3.21
WORKDIR /app

# Try to install the exact patched packages, else fallback to upgrading any busybox packages
RUN set -eux; \
    apk update; \
    (apk add --no-cache \
       busybox=1.37.0-r14 \
       busybox-binsh=1.37.0-r14 \
       busybox-ssl_client=1.37.0-r14 \
     || apk upgrade busybox busybox-binsh busybox-ssl_client)

# Copy dependency files first to cache layers
COPY package*.json ./

# Install dependencies (use npm ci if lockfile exists)
RUN if [ -f package-lock.json ]; then npm ci --only=production; else npm install --production; fi

# Copy app and run as non-root
COPY . .
RUN addgroup -S appgroup && adduser -S appuser -G appgroup && chown -R appuser:appgroup /app
USER appuser

EXPOSE 8080
CMD ["node", "index.js"]
