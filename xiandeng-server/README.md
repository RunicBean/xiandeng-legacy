# dorian-xiandeng.net.cn/server

# What's the purpose

# 目录结构
```
conf/ - 环境配置文件
config/ - 配置定义
config/app_configs.go - 应用层配置
```

# Development
Overall generation, please run:
```bash
go generate ./...
```

## Go modules
- Go 1.21+ required.
- Golang modules installation
```bash
go mod tidy
```

## Database model generation
If you'd like to update db models with your schema, use sqlc.
It bases on three files:
1. query.sql - what SQL stanza you'll use, from where sqlc will generate DAO interfaces
2. schema.sql - DML stanza for all tables required
3. sqlc.yml - sqlc configuration file
go to `db` folder
```bash
cd db
```
generate
```bash
go run github.com/sqlc-dev/sqlc/cmd/sqlc generate
```

## Database Migration

## GraphQL Generation
```bash
go run github.com/99designs/gqlgen generate
```

## Swagger CMD Installation
```bash
go install github.com/swaggo/swag/cmd/swag@latest
```
之后通过`swag init`命令生成swagger doc文件。
> 注意：在生成swagger文档时，需要根目录存在 main.go 文件。从 cmd/server 下复制 main.go 文件到根目录,
> 然后在根目录执行 swag init。由于根目录的 main.go 文件被加入了 .gitignore，所以不用担心被上传至 git。

# Code Structure

# Deployment
## Network
为了保证创建的postgres和go容器能够互相通信，需要先创建一个bridge网络，然后把两个应用都部署到这个网络下。
## Environment Variables
- `env`: `dev`, `pro`
## Docker run
`docker run --name xiandeng-server --network yanban -v /www/wwwroot/yanban/conf:/app/conf -p 8080:8080 -d registry-vpc.cn-shanghai.aliyuncs.com/dorian-acr/xiandeng-server:265da0f055952799d142642930b856f634ea6d81`
## Postgres
Image: `postgres:14`
1. 跑在Docker容器，用最简形式的部署方式：`docker run --name some-postgres --network yanban -v /www/postgres/data:/var/lib/postgresql/data -e POSTGRES_PASSWORD=mysecretpassword -p 5432:5432 -d postgres`
2. 操作pg `psql -h some-postgres -U postgres`

## Checklist
1. migration 文件是否被copy到了生产目录
2. docker run 时是否挂载config文件
