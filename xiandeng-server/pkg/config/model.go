package config

import "xiandeng.net.cn/server/pkg/log"

type Config struct {
	Server struct {
		Env           string
		WebDomain     string
		SessionSecret string
		ProductDomain string
	}
	Auth struct {
		WxAppID     string
		WxAppSecret string
		JwtKey      string
	}
	OSS struct {
		Product         string
		Bucket          string
		Endpoint        string
		AccessKeyId     string
		AccessKeySecret string
	}
	Database struct {
		DbName   string
		CredInfo string
	}
	Payment struct {
		MchId                      string
		MchCertificateSerialNumber string
		MchAPIv3Key                string
	}
	Data struct {
		LlmAPIKey string
	}
	TaskManager struct {
		WorkerCount    int
		TimeoutSeconds int
	}
	Redis struct {
		Addr     string
		Password string
	}
	IMAP struct {
		Host     string
		Port     int
		Username string
		Password string
	}
	Admin struct {
		Pass string
	}
	Logger log.LoggerConfig
}

func (c Config) WebUrlPrefix() string {
	return "https://" + c.Server.WebDomain
}
