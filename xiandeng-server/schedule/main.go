package schedule

import (
	"github.com/robfig/cron/v3"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/pkg/log"
	"xiandeng.net.cn/server/services/product"
)

type Scheduler struct {
	repo db.Repository
	cron *cron.Cron
}

type SchedulerFunc func(repository db.Repository)

func (s *Scheduler) AddFunc(spec string, f SchedulerFunc) {
	s.cron.AddFunc(spec, func() {
		f(s.repo)
	})
}

func (s *Scheduler) Start() {
	s.cron.Start()
}

func (s *Scheduler) Stop() {
	s.cron.Stop()
}

type cronLogger struct {
	l *log.Logger
}

func (c cronLogger) Printf(msg string, args ...interface{}) {
	c.l.Sugar().Infof(msg, args...)
}

func NewScheduler(r db.Repository, logger *log.Logger) *Scheduler {
	sc := &Scheduler{repo: r}
	// Debug Usage
	sc.cron = cron.New(cron.WithSeconds(), cron.WithLogger(
		cron.VerbosePrintfLogger(cronLogger{l: logger})))
	// sc.cron = cron.New(cron.WithSeconds())

	sc.AddFunc("0 0 * * * *", func(r db.Repository) {
		product.UpdateRecruit(r)
	})
	return sc
}
