FROM node:22-alpine AS builder

WORKDIR /app
COPY .output/ .output/
COPY package.json ./
COPY node_modules/ node_modules/

# Verify build
RUN node .output/server/index.mjs --help 2>&1 || node .output/server/index.mjs 2>&1 || true

FROM node:22-alpine AS runtime

RUN addgroup -g 1000 -S qrs && adduser -u 1000 -S qrs -G qrs
WORKDIR /app
COPY --from=builder --chown=qrs:qrs /app/.output/ .output/
COPY --from=builder --chown=qrs:qrs /app/node_modules ./node_modules/
COPY --from=builder --chown=qrs:qrs /app/package.json ./

USER qrs
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000', r => process.exit(r.statusCode === 200 ? 0 : 1))" || exit 1

CMD ["node", ".output/server/index.mjs"]
