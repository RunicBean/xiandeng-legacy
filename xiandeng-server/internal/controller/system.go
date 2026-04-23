package controller

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"xiandeng.net.cn/server/pkg/security"

	"github.com/RichardKnop/machinery/v2/tasks"
	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"xiandeng.net.cn/server/constants"
	"xiandeng.net.cn/server/internal/app"
	"xiandeng.net.cn/server/internal/code"
	"xiandeng.net.cn/server/internal/controller/response_model"
	"xiandeng.net.cn/server/internal/services"
	timeutil "xiandeng.net.cn/server/pkg/utils/time_util"
	"xiandeng.net.cn/server/tasks/server"
)

type SystemController struct {
	*Controller
	taskClient  server.TaskClient
	fsService   services.FileSystemService
	imapService services.ImapService
	dataService services.DataService
}

func NewSystemController(controller *Controller, taskClient server.TaskClient, fsService services.FileSystemService, imapService services.ImapService, dataService services.DataService) *SystemController {
	return &SystemController{
		Controller:  controller,
		taskClient:  taskClient,
		fsService:   fsService,
		imapService: imapService,
		dataService: dataService,
	}
}

type ParamWebhookGet struct {
	Echostr string `json:"echostr" form:"echostr" example:"echostr"` // 微信验证webhook接口时的字符串，需要返回
}

// WebhookHandler 回调接口
// @Summary 回调接口
// @Description 回调接口
// @Tags 系统
// @Produce application/json
// @Param object query ParamWebhookGet false "微信验证webhook接口时的字符串，需要返回"
// @Success 200
// @Router /system/webhook [get]
func (c *SystemController) WebhookGet() app.HandlerFunc {
	return func(ctx app.Context) {
		gctx := ctx.GinContext()
		// 1. 响应echostr使用
		echostr, echostrExists := gctx.GetQuery("echostr")
		if echostrExists {
			gctx.String(http.StatusOK, echostr)
			return
		}

	}
}

func (c *SystemController) WebhookPost() app.HandlerFunc {
	return func(ctx app.Context) {
		body, err := io.ReadAll(ctx.GetRequest().Body)
		if err != nil {
			ctx.AbortWithStatusJSON(
				http.StatusInternalServerError,
				code.ServerInternalErr,
				fmt.Sprintf("request body error: %x", err),
				err,
			)
			return
		}
		fmt.Println(body)
		ctx.SuccessJSON("ok")
	}
}

func (c *SystemController) Health() app.HandlerFunc {
	return func(ctx app.Context) {
		// Purpose: Provide a dependency-light readiness endpoint for E2E smoke tests and local checks.
		// Outputs: Minimal JSON payload so tests can assert service boot + middleware/trace behavior.
		ctx.SuccessJSON(map[string]string{
			"status": "ok",
		})
	}
}

func ping(ws *websocket.Conn, done chan string) {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()
	for {
		select {
		case <-ticker.C:

			if _, _, err := ws.ReadMessage(); err != nil {
				done <- "closed"
				return
			}
		case <-done:
			return
		}
	}
}

// WebhookHandler websocket测试
// @Summary websocket测试
// @Description websocket测试
// @Tags 系统
// @Produce application/json
// @Success 200
// @Router /system/current_time [get]
func (c *SystemController) CurrentTime() gin.HandlerFunc {
	return func(c *gin.Context) {
		upGrader := websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true
			},
			HandshakeTimeout: time.Second,
			// ReadBufferSize:  1024,
			// WriteBufferSize: 1024,
		}

		ws, err := upGrader.Upgrade(c.Writer, c.Request, nil)
		if err != nil {
			panic(err)
		}
		defer func() {
			fmt.Println("closing ws")
			err := ws.Close()
			if err != nil {
				panic(err)
			}
		}()
		var done chan string = make(chan string)
		defer func() {
			close(done)
		}()
		go ping(ws, done)
		for {

			// Prepare your object.
			currentTime := timeutil.NowInShanghai()
			t := &response_model.Time{
				UnixTime:  int(currentTime.Unix()),
				TimeStamp: currentTime.Format(time.RFC3339),
			}

			select {
			case <-done:
				fmt.Println("client close conn.")
				return
			default:
				err = ws.WriteJSON(t)
				if err != nil {
					done <- "closed"
					return
				}
			}
			time.Sleep(1 * time.Second)
			fmt.Println("Tick")
		}
	}
}

type BodyLogMessage struct {
	Message string `json:"message" form:"message"`
}

// LogMessage 写日志
// @Summary 写日志
// @Description 写日志
// @Tags 系统
// @Accept json
// @Produce application/json
// @Param BodyLogMessage body BodyLogMessage false "BodyLogMessage"
// @Success 200
// @Router /system/log_message [post]
func (c *SystemController) LogMessage() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyLogMessage
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		u := ctx.User()
		fmt.Println(map[string]string{
			"UserNick": u.Nickname,
			"UserId":   u.ID.String(),
			"Message":  body.Message,
		})
	}
}

// LogMessage 写普通日志
// @Summary 写普通日志
// @Description 写普通日志
// @Tags 系统
// @Accept json
// @Produce application/json
// @Param BodyLogMessage body BodyLogMessage false "BodyLogMessage"
// @Success 200
// @Router /system/log_common_message [post]
func (c *SystemController) LogCommonMessage() app.HandlerFunc {
	return func(ctx app.Context) {
		var body BodyLogMessage
		err := ctx.ShouldBind(&body)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		fmt.Println(map[string]string{

			"Message": body.Message,
		})
	}
}

// @Summary TestTask
// @Tags 系统
// @Description TestTask
// @Router /system/test_task [get]
func (c *SystemController) TestTask() app.HandlerFunc {
	return func(ctx app.Context) {
		sig := &tasks.Signature{
			Name: "email_delivery",
			Args: []tasks.Arg{
				{
					Type:  "string",
					Value: "src urllll",
				},
			},
		}
		r, _ := c.taskClient.SendTaskWithContext(ctx.GinContext(), sig)
		state := make(chan *tasks.TaskState)
		go func() {
			for {
				s := r.GetState()
				if s.IsCompleted() {
					state <- s
				}
			}
		}()

		select {
		case <-state:
			d, _ := r.Get(0)
			ctx.SuccessJSON(d[0].Interface())
			return
		case <-time.After(time.Second * 10):
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, "timeout", errors.New("timeout"))
			return
		}
		// r.GetState()
		// d, _ := r.Get(0)
		// ctx.SuccessJSON(d)
		// log.GetLogger().Info(fmt.Sprintf("enqueued task: id=%s, type=%s", info.ID, info.Type), "test_task")
		// fmt.Println(info.Result)
	}
}

// @Summary UploadOrderProof
// @Description 上传订单凭证
// @Tags 系统
// @Accept multipart/form-data
// @Param order_id path string true "order_id"
// @Produce application/json
// @Param file formData file true "file"
// @Success 201
// @Router /system/order/proof/{order_id} [post]
func (c *SystemController) UploadOrderProof() app.HandlerFunc {
	return func(ctx app.Context) {
		orderId := ctx.Param("order_id")
		form, err := ctx.MultipartForm()
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		files := form.File["file[]"]
		for _, file := range files {
			buf, err := file.Open()
			if err != nil {
				ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, err.Error(), err)
				return
			}
			defer buf.Close()

			fileNameLst := strings.Split(file.Filename, ".")
			ext := fileNameLst[len(fileNameLst)-1]
			err = c.fsService.UploadOrderProof(orderId, buf, ext)
			if err != nil {
				ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, err.Error(), err)
				return
			}
		}
		ctx.SuccessJSON("ok")
	}
}

// @Summary 列出订单凭证
// @Description 列出订单凭证
// @Tags 系统
// @Param order_id path string true "order_id"
// @Produce application/json
// @Success 200
// @Router /system/order/proof/{order_id} [get]
func (c *SystemController) ListOrderProof() app.HandlerFunc {
	return func(ctx app.Context) {
		data, err := c.fsService.ListOrderProof(ctx.Param("order_id"))
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(data)
	}
}

func (c *SystemController) TestImapFetch() app.HandlerFunc {
	return func(ctx app.Context) {
		err := c.imapService.Fetch("明细对账单2", false)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, err.Error(), err)
			return
		}
		ctx.SuccessCreateJSON("ok")
	}
}

func (c *SystemController) GetWording() app.HandlerFunc {
	return func(ctx app.Context) {
		ns := ctx.Param("ns")
		namespace := constants.WordingNamespace(ns)
		if !namespace.IsValid() {
			ctx.AbortWithBadRequest(errors.New("invalid namespace: " + ns))
			return
		}
		data, err := c.dataService.GetWording(ctx.RequestContext(), namespace)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.DBQueriesExecErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(data)
	}
}

type GenerateHashPasswordReq struct {
	Password string `json:"password" form:"password"`
}

func (c *SystemController) GenerateHashPassword() app.HandlerFunc {
	return func(ctx app.Context) {
		req := GenerateHashPasswordReq{}
		err := ctx.ShouldBind(&req)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		hash, err := security.HashPassword(req.Password)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusInternalServerError, code.ServerInternalErr, err.Error(), err)
			return
		}
		ctx.SuccessJSON(hash)
	}
}

type CheckHashPasswordReq struct {
	Password string `json:"password" form:"password"`
	Hash     string `json:"hash" form:"hash"`
}

func (c *SystemController) CheckHashPassword() app.HandlerFunc {
	return func(ctx app.Context) {
		req := CheckHashPasswordReq{}
		err := ctx.ShouldBind(&req)
		if err != nil {
			ctx.AbortWithBadRequest(err)
			return
		}
		if security.CheckPasswordHash(req.Password, req.Hash) {
			ctx.SuccessJSON(true)
		} else {
			ctx.SuccessJSON(false)
		}
	}
}
