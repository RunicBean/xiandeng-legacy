# Development
Running air for hot reloading in Golang.
Firstly, you need to install air.
`go install github.com/air-verse/air@latest`
To run air, you need to run the following command:
```shell
# Run server
air -c cmd/development/server.air.toml
# Run task worker
air -c cmd/development/worker.air.toml
```