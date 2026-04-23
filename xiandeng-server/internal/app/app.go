package app

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"time"

	"github.com/gin-contrib/sessions"
	"github.com/gin-contrib/sessions/cookie"
	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	cors "github.com/rs/cors/wrapper/gin"
	"go.uber.org/zap"
	"xiandeng.net.cn/server/pkg/log"
)

type Option func(*option)

type option struct {
	enableCors            bool
	enableSession         bool
	enableMultipartMemory bool
	corsOptions           CorsOptions
	sessionOptions        SessionOptions
	maxMultipartMemory    int64
}

type CorsOptions struct {
	AllowedOrigins   []string
	AllowCredentials bool
	MaxAge           int
	AllowedMethods   []string
	AllowedHeaders   []string
}

type SessionOptions struct {
	Secret string
	Name   string
	MaxAge int
}

type WebServer struct {
	httpSrv *http.Server
	engine  *gin.Engine
}

func (s *WebServer) GetEngine() *gin.Engine {
	return s.engine
}

func WithEnableCors(corsOptions CorsOptions) Option {
	return func(opt *option) {
		opt.enableCors = true
		opt.corsOptions = corsOptions
	}
}

func WithMultipartMemory(size int64) Option {
	return func(opt *option) {
		opt.enableMultipartMemory = true
		opt.maxMultipartMemory = size
	}
}

func WithSession(options SessionOptions) Option {
	return func(opt *option) {
		opt.enableSession = true
		opt.sessionOptions = options
	}
}

func WithReleaseMode(isProd bool) Option {
	return func(opt *option) {
		if isProd {
			gin.SetMode(gin.ReleaseMode)
		}
	}
}

func NewServer(logger *log.Logger, appOptions ...Option) (s *WebServer, err error) {

	opt := new(option)
	for _, f := range appOptions {
		f(opt)
	}

	s = &WebServer{
		engine: gin.New(),
	}

	if opt.enableCors {
		s.EnableCors(opt.corsOptions)
	}
	//s.engine.AllowMethods(iris.MethodOptions)

	if opt.enableSession {
		s.EnableSession(opt.sessionOptions)
	}

	if opt.enableMultipartMemory {
		s.engine.MaxMultipartMemory = opt.maxMultipartMemory
	}
	s.Use(gin.Recovery())

	// Purpose: Provide a single per-request middleware that (1) binds logger/trace to gin.Context and
	// (2) emits one structured access log line after handlers complete.
	// Inputs: Incoming HTTP headers (trace id), request metadata.
	// Outputs: Response headers (trace id); structured logs via zap.
	// SideEffects: Mutates gin.Context keys used by appContext (logger/trace/user/account).
	s.Use(func(c *gin.Context) {
		start := time.Now()

		ctx := newContext(c)
		defer releaseContext(ctx)

		ctx.setLogger(logger)
		ctx.setTrace()
		ctx.setWSUpgrader(websocket.Upgrader{
			// 解决跨域问题
			CheckOrigin: func(r *http.Request) bool {
				return true
			},
		}, // use default options
		)

		c.Next()

		status := c.Writer.Status()
		logLine := ctx.Logger()
		if logLine == nil {
			return
		}
		fields := []zap.Field{
			zap.String("method", c.Request.Method),
			zap.String("path", c.Request.URL.Path),
			zap.String("route", c.FullPath()),
			zap.Int("status", status),
			zap.Int("bytes", c.Writer.Size()),
			zap.Duration("latency", time.Since(start)),
			zap.String("client_ip", c.ClientIP()),
			zap.String("user_agent", c.Request.UserAgent()),
		}
		switch {
		case status >= http.StatusInternalServerError:
			logLine.Error("http.access", fields...)
		case status >= http.StatusBadRequest:
			logLine.Warn("http.access", fields...)
		default:
			logLine.Info("http.access", fields...)
		}
	})

	//s.Use(func(c *gin.Context) {
	//	c.Set(constants.INTERNAL_RESOURCE_CONTEXT_NAME, intResource)
	//	c.Next()
	//})

	return s, nil
}

func (s *WebServer) EnableCors(options CorsOptions) {
	s.engine.Use(cors.New(cors.Options{
		AllowedOrigins:   options.AllowedOrigins,
		AllowedMethods:   options.AllowedMethods,
		AllowedHeaders:   options.AllowedHeaders,
		AllowCredentials: options.AllowCredentials,
		MaxAge:           options.MaxAge,
	}))
}

func (s *WebServer) EnableSession(options SessionOptions) {
	store := cookie.NewStore([]byte(options.Secret))
	s.Use(sessions.Sessions(options.Name, store))
}

func (s *WebServer) EnableRecover() {

}

//Router Handler

func HandlerWrap(handlers ...HandlerFunc) []gin.HandlerFunc {
	returnFuncs := make([]gin.HandlerFunc, len(handlers))
	for i, handler := range handlers {

		// Please note here: if handler be executed later, handler := handler can make we pass different handler to gin
		handler := handler

		returnFuncs[i] = func(gctx *gin.Context) {
			ctx := newContext(gctx)
			defer releaseContext(ctx)
			handler(ctx)
		}
	}
	return returnFuncs
}

type RouterGroup interface {
	GET(relativePath string, handlers ...HandlerFunc)
	POST(relativePath string, handlers ...HandlerFunc)
	PATCH(relativePath string, handlers ...HandlerFunc)
	DELETE(relativePath string, handlers ...HandlerFunc)
	Any(relativePath string, handlers ...HandlerFunc)
	Group(relativePath string, handlers ...HandlerFunc) RouterGroup
}

type routerGroup struct {
	group *gin.RouterGroup
}

var _ RouterGroup = (*routerGroup)(nil)

func (g *routerGroup) Group(relativePath string, handlers ...HandlerFunc) RouterGroup {
	return &routerGroup{
		g.group.Group(relativePath, HandlerWrap(handlers...)...),
	}
}

func (g *routerGroup) GET(relativePath string, handlers ...HandlerFunc) {
	g.group.GET(relativePath, HandlerWrap(handlers...)...)
}

func (g *routerGroup) POST(relativePath string, handlers ...HandlerFunc) {
	g.group.POST(relativePath, HandlerWrap(handlers...)...)
}

func (g *routerGroup) PATCH(relativePath string, handlers ...HandlerFunc) {
	g.group.PATCH(relativePath, HandlerWrap(handlers...)...)
}

func (g *routerGroup) DELETE(relativePath string, handlers ...HandlerFunc) {
	g.group.DELETE(relativePath, HandlerWrap(handlers...)...)
}

func (g *routerGroup) Any(relativePath string, handlers ...HandlerFunc) {
	g.group.Any(relativePath, HandlerWrap(handlers...)...)
}

func (s *WebServer) Group(relativePath string, handlers ...HandlerFunc) RouterGroup {
	return &routerGroup{
		s.engine.Group(relativePath, HandlerWrap(handlers...)...),
	}
}

func (s *WebServer) Use(middleware gin.HandlerFunc) {
	s.engine.Use(middleware)
}

func definePort() string {
	const defaultPort = "8080"

	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}
	return port
}

func (s *WebServer) Run() error {
	s.httpSrv = &http.Server{
		Addr:    ":" + definePort(),
		Handler: s.GetEngine(),
	}

	go func() {
		if err := s.httpSrv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			fmt.Println("http server startup err", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt)
	<-quit

	return s.Stop()
}

func (s *WebServer) Stop() error {
	fmt.Println("Shutdown Server ...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := s.httpSrv.Shutdown(ctx); err != nil {
		return fmt.Errorf("server Shutdown: %v", err)
	}
	fmt.Print("Server exiting")
	return nil
}
