package config

import (
	"fmt"
	"log"
	"reflect"
	"strings"

	"xiandeng.net.cn/server/pkg/env"
	"xiandeng.net.cn/server/pkg/flags"

	"github.com/fsnotify/fsnotify"
	"github.com/spf13/viper"
)

// 自定义解码器处理字符串端口号
func decodeHookFuncStringToInt(f reflect.Kind, t reflect.Kind, data interface{}) (interface{}, error) {
	// if f == reflect.String && t == reflect.Int {
	// 	return strconv.Atoi(data.(string))
	// }
	// fmt.Println(f.String())
	// fmt.Println(data)
	return data, nil
}

// LoadConfConfig load config from conf file
func LoadConfConfig(fm *flags.FlagManager) *Config {
	conf := &Config{}
	if fm.ConfPath == "" {
		panic("config file path. i.e. -conf conf/local_config.yaml")
	}
	fmt.Println("confPath:", fm.ConfPath)
	confIns := viper.New()
	confIns.SetConfigFile(fm.ConfPath)

	if err := confIns.ReadInConfig(); err != nil { // Handle errors reading the config datastore
		panic(fmt.Errorf("fatal error config datastore: %w", err))
	}
	if err := confIns.Unmarshal(conf, viper.DecodeHook(decodeHookFuncStringToInt)); err != nil {
		panic(fmt.Errorf("fatal error config datastore: %w", err))
	}

	EnvPrepare(conf)

	confIns.OnConfigChange(func(e fsnotify.Event) {
		fmt.Println("Config datastore changed:", e.Name)
		if err := confIns.Unmarshal(conf); err != nil {
			panic(fmt.Errorf("fatal error config datastore: %w", err))
		}
		EnvPrepare(conf)
	})
	confIns.WatchConfig()

	return conf
}

// LoadEnvConfig load config from env
func LoadEnvConfig() *Config {
	conf := &Config{}
	if err := viperBindEnvs(viperEnvNames); err != nil {
		log.Fatalf("Loading env config error: %v", err)
	}
	replacer := strings.NewReplacer(".", "_")
	viper.SetEnvKeyReplacer(replacer)
	if err := viper.Unmarshal(conf); err != nil {
		panic(fmt.Errorf("fatal error config datastore: %w", err))
	}

	EnvPrepare(conf)

	viper.OnConfigChange(func(e fsnotify.Event) {
		fmt.Println("Config datastore changed:", e.Name)
		if err := viper.Unmarshal(conf); err != nil {
			panic(fmt.Errorf("fatal error config datastore: %w", err))
		}
		EnvPrepare(conf)
	})
	viper.WatchConfig()
	return conf
}

func viperBindEnvs(envNames []string) (err error) {
	for _, name := range envNames {
		err = viper.BindEnv(name)
		if err != nil {
			return
		}
	}
	return nil
}

var viperEnvNames = []string{
	"Database.CredInfo", // Will detect DATABASE_CREDINFO env name
}

// EnvPrepare will process anything related to environments
func EnvPrepare(conf *Config) {
	// File/Path Existence Check
	// if err := sys.MakeSureExistence(configInstance.FileSystem.LocalTempDir); err != nil {
	// 	panic(err)
	// }
	e := env.Active()
	if e == nil {
		fmt.Println("env is not set, use env in conf file:", conf.Server.Env)
		env.SetEnv(conf.Server.Env)
	}
	if env.Active() == nil {
		panic("env should be set either in Conf file or flag -env.")
	}
}
