##### DEPENDENCIES

FROM --platform=linux/amd64 node:16-alpine3.17 AS deps
RUN apk add --no-cache libc6-compat openssl1.1-compat

WORKDIR /app

# Install Prisma Client - remove if not using Prisma

COPY ./governance/governance-ui/prisma ./

# Install dependencies based on the preferred package manager

COPY ./governance/governance-ui/package.json ./governance/governance-ui/yarn.lock* ./governance/governance-ui/package-lock.json* ./governance/governance-ui/pnpm-lock.yaml\* ./

RUN \
    if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci; \
    elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i; \
    else echo "Lockfile not found." && exit 1; \
    fi

##### BUILDER

FROM --platform=linux/amd64 node:16-alpine3.17 AS builder

# Install schema-tools
RUN npm install --global typescript
WORKDIR /schema-tools
COPY ./governance/schema-tools/package.json ./governance/schema-tools/package-lock.json /schema-tools/
RUN npm ci
COPY ./governance/schema-tools/ /schema-tools/
RUN tsc && npm link


WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY ./governance/governance-ui/ .

ENV NEXT_TELEMETRY_DISABLED 1

RUN npm link @phac-aspc-dgg/schema-tools

RUN \
    if [ -f yarn.lock ]; then SKIP_ENV_VALIDATION=1 yarn build; \
    elif [ -f package-lock.json ]; then SKIP_ENV_VALIDATION=1 npm run build; \
    elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && SKIP_ENV_VALIDATION=1 pnpm run build; \
    else echo "Lockfile not found." && exit 1; \
    fi

##### RUNNER

FROM --platform=linux/amd64 node:16-alpine3.17 AS runner

WORKDIR /app

ENV NODE_ENV production

ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/next.config.mjs ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000

ENV PORT 3000
ENV WS_PORT 3001

CMD ["node", "server.js"]
