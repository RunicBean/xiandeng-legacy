package flags

import "flag"

type FlagManager struct {
	ConfPath string
	Env      string
}

func NewFlagManager() *FlagManager {
	env := flag.String("env", "", "dev\n fat\n uat\n pro\n")
	confPath := flag.String("conf", "conf/local_config.yaml", "config file path. i.e. -conf conf/local_config.yaml")
	flag.Parse()
	return &FlagManager{
		Env:      *env,
		ConfPath: *confPath,
	}
}
