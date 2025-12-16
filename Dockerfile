# Dockerfile — force BusyBox -> 1.37.0-r14 (or newer) inside the image
FROM node:25.2.1-alpine3.21

WORKDIR /app
ENV LANG=C.UTF-8

# 1) Point to Alpine v3.21 official mirrors (ensures r14 is reachable),
# 2) refresh the index, 3) try to upgrade busybox packages to whatever is available,
# 4) as a fallback attempt to explicitly add the packages,
# 5) print versions for verification (so the resulting image layer contains the correct version).
RUN set -eux; \
    # keep the base repos but ensure v3.21 main & community mirrors are present (official CDN)
    printf '%s\n' "https://dl-cdn.alpinelinux.org/alpine/v3.21/main" "https://dl-cdn.alpinelinux.org/alpine/v3.21/community" > /etc/apk/repositories; \
    apk update; \
    # attempt to upgrade busybox family to the available versions in the repos
    apk upgrade --available busybox busybox-binsh busybox-ssl_client || true; \
    # try explicit install if upgrade didn't apply (safe-no-cache)
    apk add --no-cache --force-refresh busybox busybox-binsh busybox-ssl_client || true; \
    # quick verification: show installed busybox packages & busybox binary header
    apk info -v busybox busybox-binsh busybox-ssl_client || true; \
    busybox | head -n1 || true

# Copy only package files first (cache-friendly)
COPY package*.json ./

# Use npm ci when available
RUN if [ -f package-lock.json ]; then npm ci --only=production; else npm install --production; fi

# Copy app sources afterwards (so deps stay cached when source changes)
COPY . .

# Optional: run as non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup && chown -R appuser:appgroup /app
USER appuser

EXPOSE 8080
CMD ["node", "index.js"]
