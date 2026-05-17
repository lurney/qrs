# ── Builder: install deps + build Nuxt ──────────────────
FROM node:22-alpine AS builder

WORKDIR /app
RUN corepack enable && corepack prepare pnpm@10.7.1 --activate

COPY . .
RUN pnpm install --frozen-lockfile
RUN pnpm run build

# ── Runtime: minimal image ──────────────────────────────
FROM node:22-alpine AS runtime

RUN addgroup -S app && adduser -S app -G app
WORKDIR /app

COPY --from=builder --chown=app:app /app/.output/ .output/
COPY --from=builder --chown=app:app /app/node_modules ./node_modules/
COPY --from=builder --chown=app:app /app/package.json ./

USER app
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000', r => process.exit(r.statusCode === 200 ? 0 : 1))" || exit 1

CMD ["node", ".output/server/index.mjs"]
