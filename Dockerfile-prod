FROM node:10.1
WORKDIR /user/src/app
COPY . /user/src/app
RUN npm install
RUN npm run build
EXPOSE 3000
ENTRYPOINT ["node", "./server/server.js"]