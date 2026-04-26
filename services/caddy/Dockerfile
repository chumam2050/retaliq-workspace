# Build Caddy with the Cloudflare DNS plugin
FROM caddy:builder-alpine AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/fabriziosalmi/caddy-waf

# Final image
FROM caddy:alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

COPY docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

# Set entrypoint dan command default Caddy
ENTRYPOINT ["docker-entrypoint.sh"]