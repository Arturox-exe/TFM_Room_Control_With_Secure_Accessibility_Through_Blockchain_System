#Primera Etapa
FROM node:10.24.1 as build-step

RUN mkdir -p /app

WORKDIR /app

COPY package.json /app

COPY package-lock.json /app

RUN npm install

COPY . /app

EXPOSE 4000

CMD [ "node", "app.js" ]