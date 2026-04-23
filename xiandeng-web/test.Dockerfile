ARG NODE_VERSION=node:18.12.1-alpine
ARG ENV=prod

FROM $NODE_VERSION AS dependency-base

WORKDIR /app

# code
COPY . .

# install
# RUN npm config set registry https://registry.npm.taobao.org \
#   && npm config set sass_binary_site=https://npm.taobao.org/mirrors/node-sass
ENV VITE_WEB_PREFIX=${VITE_WEB_PREFIX}
RUN yarn install

# build
RUN yarn run build

# FROM nginx:1.23.3-alpine AS nginx-dev
# ENV NGINX_BINARY=nginx-debug

FROM nginx:1.23.3-alpine AS nginx-prod
ENV NGINX_BINARY=nginx

FROM nginx-${ENV} AS production
ARG ENV
RUN echo "working on ${ENV}, use nginx binary: ${NGINX_BINARY}"

COPY --from=dependency-base /app/dist /app/dist

RUN rm /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./nginx-xiandeng-test.conf /etc/nginx/conf.d/nginx-xiandeng.conf

EXPOSE 3000
CMD ["/bin/sh", "-c", "${NGINX_BINARY} -g 'daemon off;'"]
