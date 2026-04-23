package server

import (
	"context"
	"fmt"
	"github.com/RichardKnop/machinery/v2/backends/result"
	exampletasks "github.com/RichardKnop/machinery/v2/example/tasks"
	"log"

	"github.com/RichardKnop/machinery/v2"
	redisbackend "github.com/RichardKnop/machinery/v2/backends/redis"
	redisbroker "github.com/RichardKnop/machinery/v2/brokers/redis"
	mach_config "github.com/RichardKnop/machinery/v2/config"
	"github.com/RichardKnop/machinery/v2/example/tracers"
	eagerlock "github.com/RichardKnop/machinery/v2/locks/eager"
	"github.com/RichardKnop/machinery/v2/tasks"
	ga_db "xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/pkg/config"
)

var (
	consumerTag = "machinery_worker"
	//dep         *Dep
)

//func GetDep() *Dep {
//	return dep
//}
//
//// Define a struct that contains all dependencies
//type Dep struct {
//	Config config.Config
//	DB     models.DBTX
//}
//
//func (d *Dep) NewQueries() *models.Queries {
//	return models.New(d.DB)
//}
//
//func NewDep() *Dep {
//
//	config.LoadConfig()
//
//	// Initiate Configs
//	c := config.GetConfig()
//
//	// DB Migration
//	dbDsn := c.Database.CredInfo
//	db, _ := ga_db.InitDB(dbDsn)
//	dep = &Dep{
//		Config: c,
//		DB:     db,
//	}
//	return dep
//}

type TaskServer interface {
	Start() error
}

type taskServer struct {
	server     *machinery.Server
	conf       *config.Config
	repository ga_db.Repository
}

type TaskClient interface {
	SendTaskWithContext(ctx context.Context, signature *tasks.Signature) (*result.AsyncResult, error)
}

func NewTaskServer(conf *config.Config, repo ga_db.Repository) TaskServer {
	s := NewMachineryServer(conf.Redis.Addr)
	return &taskServer{
		server:     s,
		conf:       conf,
		repository: repo,
	}
}

func NewTaskClient(conf *config.Config) TaskClient {
	s := NewMachineryServer(conf.Redis.Addr)
	return s
}

func PreTaskHandler(signature *tasks.Signature) {
	log.Println("I am a start of task handler for:", signature.Name)
}

func PostTaskHandler(signature *tasks.Signature) {
	log.Println("I am an end of task handler for:", signature.Name)
}
func (s *taskServer) Start() error {
	// Register tasks
	tasksMap := map[string]interface{}{
		"task_study_suggestion": s.UpdateStudySuggestion,
		"email_delivery":        EmailDelivery,
		"image_resize":          ImageResize,
		"sum_ints":              exampletasks.SumInts,
		"sum_floats":            exampletasks.SumFloats,
		"concat":                exampletasks.Concat,
		"split":                 exampletasks.Split,
		"panic_task":            exampletasks.PanicTask,
		"long_running_task":     exampletasks.LongRunningTask,
	}

	err := s.server.RegisterTasks(tasksMap)
	if err != nil {
		panic(err)
	}

	cleanup, err := tracers.SetupTracer(consumerTag)
	if err != nil {
		return fmt.Errorf("unable to instantiate a tracer: %v", err.Error())
	}
	defer cleanup()

	// The second argument is a consumer tag
	// Ideally, each worker should have a unique tag (worker1, worker2 etc)
	worker := s.server.NewWorker(consumerTag, 0)

	// Here we inject some custom code for error handling,
	// start and end of task hooks, useful for metrics for example.
	errorHandler := func(err error) {
		log.Println("I am an error handler:", err)
	}

	worker.SetPostTaskHandler(PostTaskHandler)
	worker.SetErrorHandler(errorHandler)
	worker.SetPreTaskHandler(PreTaskHandler)

	err = worker.Launch()
	if err != nil {
		return fmt.Errorf("worker launch error: %v", err.Error())
	}
	return nil
}

func NewMachineryServer(redisAddr string) *machinery.Server {
	machConf := &mach_config.Config{
		DefaultQueue:    "machinery_tasks",
		ResultsExpireIn: 3600,
		Broker:          fmt.Sprintf("redis://%s", redisAddr),
		ResultBackend:   fmt.Sprintf("redis://%s", redisAddr),
		Redis:           &mach_config.RedisConfig{},
	}
	broker := redisbroker.NewGR(machConf, []string{redisAddr}, 0)
	backend := redisbackend.NewGR(machConf, []string{redisAddr}, 0)
	lock := eagerlock.New()
	server := machinery.NewServer(machConf, broker, backend, lock)

	return server
}
