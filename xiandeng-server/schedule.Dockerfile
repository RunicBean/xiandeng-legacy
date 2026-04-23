FROM golang:alpine AS builder

ENV APP_HOME /app
WORKDIR "$APP_HOME"

COPY go.mod ./
COPY go.sum ./
RUN go mod download
# RUN go env -w GOPROXY=https://goproxy.cn,direct \
#     && go mod download

COPY . ./
RUN go build -o scheduler xiandeng.net.cn/server/cmd/schedule

FROM alpine:latest
RUN apk add tzdata

ENV APP_HOME /app

COPY --from=builder $APP_HOME/scheduler $APP_HOME/scheduler
COPY db/migration $APP_HOME/db/migration
COPY pkg/rbac $APP_HOME/pkg/rbac

WORKDIR $APP_HOME

EXPOSE 8080
CMD ["./scheduler", "-env", "pro", "-conf", "conf/pro_config.yaml"]


