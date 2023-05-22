FROM --platform=linux/amd64 node:14
# Create app directory
WORKDIR /usr/src/app
# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied where available (npm@5+)
COPY package*.json ./
RUN npm install
RUN npm install @types/lodash@4.14.186
RUN npm install @types/sequelize@4.27.44
# Bundle app source
COPY . .
EXPOSE 3000
CMD [ "npm", "run", "prod" ]
