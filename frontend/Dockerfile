FROM --platform=linux/amd64 node:14 as builder
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM --platform=linux/amd64 nginx:alpine
COPY --from=builder /usr/src/app/dist/angular-registration-login-example /usr/share/nginx/html