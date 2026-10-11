FROM node:18-alpine

RUN apk add --no-cache iputils

WORKDIR /app

COPY package.json ./

RUN npm install --omit=dev

COPY server.js ./

EXPOSE 3000

CMD ["npm", "start"]
