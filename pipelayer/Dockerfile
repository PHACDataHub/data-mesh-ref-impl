FROM node:lts-alpine as builder

COPY package.json ./
RUN npm install

RUN mkdir /app
RUN mv ./node_modules /app
RUN mv ./package* /app
WORKDIR /app

RUN mkdir ./src && mkdir ./public
COPY src ./src
COPY public ./public
COPY tailwind.config.js .
COPY tsconfig.json .

RUN npm run build

FROM nginx:alpine

COPY ./nginx.conf /etc/nginx/nginx.conf

RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80
CMD nginx -g 'daemon off;'
