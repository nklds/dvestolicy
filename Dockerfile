FROM node:14-alpine3.17 AS deps

RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY *.js *.json ./
RUN npm ci

FROM node:14-alpine3.17 as builder

WORKDIR /app

COPY . .
COPY --from=deps /app/node_modules ./node_modules
RUN npm install && npm run build
FROM nginx:alpine as runner

ARG DOMAIN

WORKDIR /var/www/${DOMAIN}

COPY --chown=www-data:www-data . .
COPY --from=builder --chown=www-data:www-data /app/node_modules ./node_modules

# Remove any existing config files
RUN rm /etc/nginx/conf.d/*
COPY --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf
RUN sed -ri -e "s!domainhere!${DOMAIN}!g" /etc/nginx/conf.d/default.conf

EXPOSE 8098

CMD [ "nginx", "-g", "daemon off;" ]