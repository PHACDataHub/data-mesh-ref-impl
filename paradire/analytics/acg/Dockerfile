FROM node:alpine

RUN npm install --global typescript

WORKDIR /schema-tools
COPY ./governance/schema-tools/package.json ./governance/schema-tools/package-lock.json /schema-tools/
RUN npm ci
COPY ./governance/schema-tools/ /schema-tools/
RUN tsc && npm link

WORKDIR /acg

COPY ./analytics/acg/package.json ./analytics/acg/package-lock.json /acg/
RUN npm --legacy-peer-deps ci && npm --legacy-peer-deps link @phac-aspc-dgg/schema-tools
COPY ./analytics/acg/ /acg/

RUN tsc
ENTRYPOINT ["/bin/sh"]

CMD ["start.sh"]
