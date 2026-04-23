package log

type LoggerConfig struct {
	LogFileName string
	LogLevel    string //"debug" | "info" | "warn" | "error" | "fatal" | "panic"
	MaxSize     int    // Maximum size unit for each log file: M
	MaxBackups  int    // The maximum number of backups that can be saved for log files
	MaxAge      int    // Maximum number of days the file can be saved
	Compress    bool
	LogEncoding string // "console" | "json"
}
