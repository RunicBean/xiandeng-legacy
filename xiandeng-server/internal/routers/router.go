package router

import (
	"net/http"

	"xiandeng.net.cn/server/constants"
	"xiandeng.net.cn/server/docs"
	"xiandeng.net.cn/server/internal/app"

	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/env"
	"xiandeng.net.cn/server/pkg/log"
)

func NewAppServer(logger *log.Logger, conf *config.Config, deps Deps) (*app.WebServer, error) {
	// Purpose: Keep the HTTP bootstrap layer thin. Route details live in auth-grouped registrars,
	// while this function only owns server-level concerns (CORS/session/base path wiring).
	server, err := app.NewServer(
		logger,
		app.WithEnableCors(app.CorsOptions{
			AllowedOrigins: []string{
				"*",
				// "http://localhost:3000",
				// "https://sfint.airwallex.com.cn",
				// "https://airwallex.secure.force.com",
				// "https://airwallex.my.salesforce-sites.com",
			}, // allows everything, use that to change the hosts.
			AllowCredentials: true,
			MaxAge:           600,
			AllowedMethods: []string{
				http.MethodGet,
				http.MethodPost,
				http.MethodOptions,
				http.MethodHead,
				http.MethodDelete,
				http.MethodPut,
			},
			AllowedHeaders: []string{"*"},
		}),
		app.WithSession(app.SessionOptions{
			Name:   constants.SESSION_NAME,
			Secret: conf.Server.SessionSecret,
		}),
		app.WithMultipartMemory(8<<20),
		app.WithReleaseMode(env.Active().IsPro()))
	if err != nil {
		logger.Error(err.Error())
	}

	// Routes
	docs.SwaggerInfo.BasePath = "/api/v1"
	if env.Active().IsDev() {
		docs.SwaggerInfo.Host = "localhost:8080"
	} else {
		docs.SwaggerInfo.Host = "xiandeng.net.cn/server"
	}

	if err != nil {
		return nil, err
	}

	server.GetEngine().GET("current_time", deps.SystemController.CurrentTime())
	apiV1 := server.Group("/api/v1")

	// Why: Auth-grouped registrars make it explicit which endpoints are public vs protected,
	// which reduces accidental middleware drift when future routes are added.
	registerV1PublicRoutes(apiV1, deps)
	registerV1AuthedRoutes(apiV1, deps)

	return server, err

}
