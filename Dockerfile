# Baseline image from nodev16.13
FROM node:16.13

#Set up a WORKDIR for application in the container and set it to /usr/src/app.
WORKDIR /usr/src/app

# COPY all of your application files to the WORKDIR in the container
COPY . /usr/src/app

# RUN a command to npm install your node_modules in the container
RUN npm install  

#RUN a command to build your application in the container
RUN npm run build

#EXPOSE your server port (3000)
EXPOSE 3000

#Create an ENTRYPOINT where you'll run node ./server/server.js
ENTRYPOINT [ "node", "server/server.js" ]