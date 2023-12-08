FROM node:20.9.0-alpine as build

WORKDIR /src

COPY ./package.json ./package-lock.json /src/
RUN npm ci

COPY . /src/

RUN npm run compile

EXPOSE 4000

CMD ["node", "dist/index.js"]
