FROM golang:alpine AS builder

ENV APP_HOME /app
WORKDIR "$APP_HOME"

COPY go.mod ./
COPY go.sum ./
RUN go mod download
# RUN go env -w GOPROXY=https://goproxy.cn,direct \
#     && go mod download

COPY . ./
RUN go build xiandeng.net.cn/server/cmd/server

FROM alpine:latest
RUN apk add tzdata

ENV APP_HOME /app

COPY --from=builder $APP_HOME/server $APP_HOME/server
COPY db/migration $APP_HOME/db/migration
COPY pkg/rbac $APP_HOME/pkg/rbac

WORKDIR $APP_HOME

EXPOSE 8080

RUN echo "env: pro"
RUN echo "conf file: pro_config"
CMD "/app/server" "-env" "pro" "-conf" "conf/pro_config.yaml"


