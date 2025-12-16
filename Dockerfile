FROM node:25.2.1-alpine3.21

# ensure package index up-to-date and upgrade busybox if a newer package is available
RUN apk update && apk upgrade busybox
RUN npm install -g npm@9.1.3

ADD package.json .
ADD index.js .
ADD build .
COPY . .
RUN npm install

EXPOSE 8080

CMD [ "node", "index.js" ]
