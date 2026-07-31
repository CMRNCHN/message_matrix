# Multi-stage build for Message Matrix Inbox Web
FROM node:22-alpine AS builder
RUN corepack enable && corepack prepare pnpm@9.15.4 --activate
WORKDIR /app
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY packages/shared/package.json packages/shared/
COPY apps/inbox-web/package.json apps/inbox-web/
RUN pnpm install --frozen-lockfile 2>/dev/null || pnpm install
COPY packages/shared packages/shared
COPY apps/inbox-web apps/inbox-web
ARG VITE_HOMESERVER_URL=https://matrix.example.com
ARG VITE_SERVER_NAME=example.com
RUN pnpm --filter @message-matrix/inbox-web build

FROM nginx:alpine
COPY apps/inbox-web/nginx.conf /etc/nginx/conf.d/default.conf
COPY apps/inbox-web/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
COPY --from=builder /app/apps/inbox-web/dist /usr/share/nginx/html
EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
