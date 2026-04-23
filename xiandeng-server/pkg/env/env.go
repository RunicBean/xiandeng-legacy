package env

import (
	"strings"
)

var (
	active   Environment
	dev      Environment = &environment{value: "dev"}
	fat      Environment = &environment{value: "fat"}
	uat      Environment = &environment{value: "uat"}
	pro      Environment = &environment{value: "pro"}
	test     Environment = &environment{value: "test"}
	confPath *string
)

var _ Environment = (*environment)(nil)

// Environment 环境配置
type Environment interface {
	Value() string
	IsDev() bool
	IsFat() bool
	IsUat() bool
	IsPro() bool
	IsTest() bool
	t()
}

type environment struct {
	value string
}

func (e *environment) Value() string {
	return e.value
}

func (e *environment) IsDev() bool {
	return e.value == "dev"
}

func (e *environment) IsFat() bool {
	return e.value == "fat"
}

func (e *environment) IsUat() bool {
	return e.value == "uat"
}

func (e *environment) IsPro() bool {
	return e.value == "pro"
}

func (e *environment) IsTest() bool {
	return e.value == "test"
}

func (e *environment) IsNonPro() bool {
	return !e.IsPro() && e != nil
}

func (e *environment) t() {}

//func init() {
//	fm := flags.NewFlagManager()
//	switch strings.ToLower(strings.TrimSpace(fm.Env)) {
//	case "dev":
//		active = dev
//	case "fat":
//		active = fat
//	case "uat":
//		active = uat
//	case "pro":
//		active = pro
//	default:
//		active = nil
//		//fmt.Println("Warning: '-env' cannot be found, or it is illegal. The default 'fat' will be used.")
//	}
//}

func SetEnv(e string) {
	switch strings.ToLower(strings.TrimSpace(e)) {
	case "dev":
		active = dev
	case "fat":
		active = fat
	case "uat":
		active = uat
	case "pro":
		active = pro
	case "test":
		active = test
	default:
		active = nil
		//fmt.Println("Warning: '-env' cannot be found, or it is illegal. The default 'fat' will be used.")
	}
}

// Active 当前配置的env
func Active() Environment {
	return active
}
