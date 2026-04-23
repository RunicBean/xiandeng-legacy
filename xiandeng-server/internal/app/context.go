package app

import (
	commonCtx "context"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"reflect"
	"strings"
	"sync"

	"xiandeng.net.cn/server/constants"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/xuri/excelize/v2"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/pkg/log"
	"xiandeng.net.cn/server/pkg/web"
)

const (
	LoggerName           = "__logger__"
	loggerHasUserName    = "__logger_has_user__"
	loggerHasAccountName = "__logger_has_account__"
	TraceName            = "__trace__"
	UserVarName          = "__user__"
	AccountVarName       = "__account__"
	WSUpgraderName       = "__wsupgrader__"
	DemoModeVarName      = "__demo_mode__"
	traceHeaderPrimary   = "Traceid"
	traceHeaderFallbackA = "X-Request-Id"
	traceHeaderFallbackB = "X-Trace-Id"
	traceHeaderResponseA = "Traceid"
	traceHeaderResponseB = "X-Request-Id"
)

var contextPool = &sync.Pool{
	New: func() interface{} {
		return &appContext{}
	},
}

type HandlerFunc func(Context)

// type Trace trace.Trace
func newContext(gctx *gin.Context) *appContext {
	ctx := contextPool.Get().(*appContext)
	ctx.ctx = gctx
	return ctx
}

func releaseContext(ctx *appContext) {
	ctx.ctx = nil
	contextPool.Put(ctx)
}

type Context interface {
	Logger() *log.Logger
	setLogger(logger *log.Logger)

	Trace() *Trace
	setTrace()

	//Resource() internal_resources.InternalResource

	WebSocketUpgrade() (ws *websocket.Conn)
	setWSUpgrader(upgrader websocket.Upgrader)

	User() (user *models.User)
	SetUser(user *models.User)

	Account() *models.Account
	SetAccount(account *models.Account)

	DemoMode() bool
	SetDemoMode(bool)

	ShouldBind(obj any) error
	ShouldBindQuery(obj any) (err error)

	Param(string) string
	GetQuery(key string) (string, bool)
	GetRequest() (req *http.Request)
	GetRequireRoleParam() (constants.RequireRole, bool)

	JSON(code int, obj any)
	SuccessJSON(data any)
	SuccessCreateJSON(data any)
	SuccessExcel(excelFile *excelize.File, filename string) error

	LogWarn(message string, err error, params ...zapcore.ObjectMarshaler)
	FailedJSON(httpReturnCode int, internalCode code.Code, err error)
	// Abort with Error log
	AbortWithStatusJSON(code int, appCode code.Code, message string, err error, params ...zapcore.ObjectMarshaler)
	// Abort with Warn log
	AbortWithStatusJSONWarn(code int, appCode code.Code, message string, err error, params ...zapcore.ObjectMarshaler)
	// Abort without log
	Abort(code int, appCode code.Code, message string)

	AbortWithBadRequest(err error, params ...zapcore.ObjectMarshaler)

	MultipartForm() (*multipart.Form, error)

	RequestContext() CommonCtx
	GinContext() *gin.Context

	Redirect(code int, location string)
	Next()

	Header(key string, value string)
	Writer() gin.ResponseWriter

	SetCookie(name string, value string, maxAge int, path string, domain string, secure bool, httpOnly bool)
}

type appContext struct {
	ctx *gin.Context
}

type CommonCtx struct {
	commonCtx.Context
	*log.Logger
}

var _ Context = (*appContext)(nil)

func (c *appContext) SetCookie(name string, value string, maxAge int, path string, domain string, secure bool, httpOnly bool) {
	//c.ctx.SetSameSite(http.SameSiteNoneMode)
	c.ctx.SetCookie(name, value, maxAge, path, domain, secure, httpOnly)
}

func (c *appContext) setLogger(logger *log.Logger) {
	c.ctx.Set(LoggerName, logger)
}

func (c *appContext) Logger() *log.Logger {
	l, ok := c.ctx.Get(LoggerName)
	if !ok {
		return nil
	}
	return l.(*log.Logger)
}

func (c *appContext) setTrace() {
	// Purpose: Resolve or generate a trace id and bind it to this request lifecycle.
	// Inputs: Request headers Traceid / X-Request-Id / X-Trace-Id (first non-empty wins).
	// Outputs: Trace stored in gin.Context; trace id echoed back in response headers.
	// SideEffects: Enriches the request logger with trace_id (so downstream logs don't need to re-add it).
	traceId := strings.TrimSpace(c.ctx.GetHeader(traceHeaderPrimary))
	if traceId == "" {
		traceId = strings.TrimSpace(c.ctx.GetHeader(traceHeaderFallbackA))
	}
	if traceId == "" {
		traceId = strings.TrimSpace(c.ctx.GetHeader(traceHeaderFallbackB))
	}
	if traceId == "" {
		traceId = uuid.NewString()
	}

	c.ctx.Set(TraceName, &Trace{TraceId: traceId})
	c.ctx.Header(traceHeaderResponseA, traceId)
	c.ctx.Header(traceHeaderResponseB, traceId)

	l, ok := c.ctx.Get(LoggerName)
	if ok {
		c.ctx.Set(LoggerName, l.(*log.Logger).With(zap.String("trace_id", traceId)))
	}
}

func (c *appContext) Trace() *Trace {
	t, ok := c.ctx.Get(TraceName)
	if !ok {
		return nil
	}
	return t.(*Trace)
}

//func (c *appContext) Resource() internal_resources.InternalResource {
//	return c.ctx.MustGet(constants.INTERNAL_RESOURCE_CONTEXT_NAME).(internal_resources.InternalResource)
//}

func (c *appContext) setWSUpgrader(upgrader websocket.Upgrader) {
	c.ctx.Set(WSUpgraderName, upgrader)
}

func (c *appContext) WebSocketUpgrade() (ws *websocket.Conn) {
	// Purpose: Upgrade the current HTTP request to a WebSocket connection.
	// Outputs: *websocket.Conn on success; nil on failure (request-scoped error already logged).
	u, ok := c.ctx.Get(WSUpgraderName)
	if !ok {
		c.Logger().Error("no websocket upgrader available")
		return nil
	}
	upgrader := u.(websocket.Upgrader)
	ws, err := upgrader.Upgrade(c.GinContext().Writer, c.GinContext().Request, nil)
	if err != nil {
		c.Logger().Error("websocket upgrade failed", zap.Error(err))
		return nil
	}
	return ws
}

func (c *appContext) User() (user *models.User) {
	u, ok := c.ctx.Get(UserVarName)
	if !ok {
		return nil
	}
	return u.(*models.User)
}

func (c *appContext) SetUser(user *models.User) {
	c.ctx.Set(UserVarName, user)
	if user == nil {
		return
	}
	// Purpose: Bind user identity to the request logger once (avoid repeated allocations on ctx.Logger()).
	if _, ok := c.ctx.Get(loggerHasUserName); ok {
		return
	}
	l, ok := c.ctx.Get(LoggerName)
	if ok {
		c.ctx.Set(LoggerName, l.(*log.Logger).With(zap.String("midd_user_id", user.ID.String())))
		c.ctx.Set(loggerHasUserName, true)
	}
}

func (c *appContext) Account() *models.Account {
	u, ok := c.ctx.Get(AccountVarName)
	if !ok {
		return nil
	}
	return u.(*models.Account)
}

func (c *appContext) SetAccount(account *models.Account) {
	c.ctx.Set(AccountVarName, account)
	if account == nil {
		return
	}
	// Purpose: Bind account identity to the request logger once (avoid repeated allocations on ctx.Logger()).
	if _, ok := c.ctx.Get(loggerHasAccountName); ok {
		return
	}
	l, ok := c.ctx.Get(LoggerName)
	if ok {
		c.ctx.Set(LoggerName, l.(*log.Logger).With(zap.String("midd_account_id", account.ID.String())))
		c.ctx.Set(loggerHasAccountName, true)
	}
}

func (c *appContext) DemoMode() bool {
	u, ok := c.ctx.Get(DemoModeVarName)
	if !ok {
		return false
	}
	return u.(bool)
}

func (c *appContext) SetDemoMode(demoMode bool) {
	c.ctx.Set(DemoModeVarName, demoMode)
}

func (c *appContext) ShouldBind(obj any) (err error) {
	if c.IsPlainText() {
		bodyBites, err := io.ReadAll(c.ctx.Request.Body)
		x := string(bodyBites)
		fmt.Print(x)
		if err != nil {
			return err
		}
		if err := json.Unmarshal(bodyBites, &obj); err != nil {
			return err
		}
		return err
	} else {
		err = c.ctx.ShouldBind(obj)
		return
	}

}

func (c *appContext) ShouldBindQuery(obj any) (err error) {
	return c.ctx.ShouldBindQuery(obj)
}

func (c *appContext) Param(key string) (param string) {
	param = c.ctx.Param(key)
	return
}

func (c *appContext) GetQuery(key string) (string, bool) {
	return c.ctx.GetQuery(key)
}

func (c *appContext) GetRequest() (req *http.Request) {
	req = c.ctx.Request
	return
}

func (c *appContext) IsPlainText() bool {
	return strings.Contains(c.ctx.Request.Header.Get("Content-Type"), "text/plain")
}

func (c *appContext) JSON(code int, obj any) {
	c.ctx.JSON(code, obj)
}

func (c *appContext) SuccessJSON(data any) {
	valType := reflect.TypeOf(data)
	valKind := valType.Kind()
	switch valKind {
	case reflect.Array, reflect.Slice:
		c.JSON(http.StatusOK, web.JsonResult{
			ErrorCode: code.OK.Number,
			Message:   code.OK.Message,
			Data:      data,
			Total:     reflect.ValueOf(data).Len(),
			Success:   true,
		})
	default:
		c.JSON(http.StatusOK, web.JsonResult{
			ErrorCode: code.OK.Number,
			Message:   code.OK.Message,
			Data:      data,
			Success:   true,
		})
	}

}

func (c *appContext) SuccessCreateJSON(data any) {
	c.JSON(http.StatusCreated, web.JsonResult{
		ErrorCode: code.OK.Number,
		Message:   code.OK.Message,
		Data:      data,
		Success:   true,
	})
}

func (c *appContext) SuccessExcel(excelFile *excelize.File, filename string) error {
	c.ctx.Header("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
	c.ctx.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))
	c.ctx.Header("Content-Transfer-Encoding", "binary")
	c.ctx.Header("Cache-Control", "no-cache")
	c.ctx.Header("Filename", filename)

	err := excelFile.Write(c.ctx.Writer)
	if err != nil {
		c.Logger().Error(fmt.Sprintf("write excel stream: %v", err))
		return fmt.Errorf("write excel stream: %v", err)
	}
	return nil
}

func (c *appContext) FailedJSON(httpReturnCode int, internalCode code.Code, err error) {
	c.JSON(httpReturnCode, web.Json(internalCode.Number, internalCode.Message, err.Error(), false))
}

func (c *appContext) RequestContext() CommonCtx {
	return CommonCtx{
		commonCtx.Background(),
		c.Logger(),
	}
}

func (c *appContext) GinContext() *gin.Context {
	return c.ctx
}

func (c *appContext) Redirect(code int, location string) {
	c.ctx.Redirect(code, location)
}

func (c *appContext) MultipartForm() (*multipart.Form, error) {
	return c.ctx.MultipartForm()
}

func (c *appContext) AbortWithStatusJSON(code int, appCode code.Code, message string, err error, params ...zapcore.ObjectMarshaler) {
	c.Logger().With(zap.String("uri", c.GinContext().Request.URL.Path)).ErrorTraceback(fmt.Sprintf("%s: %v", appCode.Message, message), err, params...)
	// fmt.Printf("error occurred: %v\n", data)
	c.ctx.AbortWithStatusJSON(code, web.Json(appCode.Number, appCode.Message, message, false))
}

func (c *appContext) AbortWithStatusJSONWarn(code int, appCode code.Code, message string, err error, params ...zapcore.ObjectMarshaler) {
	c.Logger().With(zap.String("uri", c.GinContext().Request.URL.Path)).Warn(fmt.Sprintf("%s: %v", appCode.Message, message), zap.Error(err), zap.Objects("params", params))
	// fmt.Printf("error occurred: %v\n", data)
	c.ctx.AbortWithStatusJSON(code, web.Json(appCode.Number, appCode.Message, message, false))
}

func (c *appContext) LogWarn(message string, err error, params ...zapcore.ObjectMarshaler) {
	c.Logger().With(zap.String("uri", c.GinContext().Request.URL.Path)).Warn(message, zap.Error(err), zap.Objects("params", params))
}

func (c *appContext) Abort(code int, appCode code.Code, message string) {
	c.ctx.AbortWithStatusJSON(code, web.Json(appCode.Number, appCode.Message, message, false))
}

func (c *appContext) AbortWithError(code int, err error) {
	c.ctx.AbortWithError(code, err)
}

func (c *appContext) AbortWithBadRequest(err error, params ...zapcore.ObjectMarshaler) {
	// log.GetLogger().Info(fmt.Sprintf("%v", data), "400")
	c.AbortWithStatusJSONWarn(
		http.StatusBadRequest,
		code.InvalidParams,
		err.Error(),
		err,
		params...,
	)
}

func (c *appContext) Header(key string, value string) {
	c.ctx.Header(key, value)
}

func (c *appContext) Writer() gin.ResponseWriter {
	return c.ctx.Writer
}

func (c *appContext) Next() {
	c.ctx.Next()
}

func (c *appContext) GetRequireRoleParam() (constants.RequireRole, bool) {
	var requireRole string
	requireRole, ok := c.GetQuery("require_role")
	if ok && requireRole != "" {
		return constants.RequireRole(requireRole), true
	} else {
		s := c.GetRequest().Header.Get("X-Requirerole")
		if s != "" {
			return constants.RequireRole(s), true
		} else {
			return "", false
		}
	}
}
