FROM node:alpine AS build

ARG NODE_ENV=production

WORKDIR /home/node/app
COPY . .
RUN npm ci

USER node
CMD npm start

EXPOSE 3000