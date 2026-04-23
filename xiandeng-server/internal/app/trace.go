package app

type Trace struct {
	TraceId        string `json:"trace_id"`
	SpanId         string `json:"span_id"`
	ParentSpanId   string `json:"parent_span_id"`
	StartTime      int64  `json:"start_time"`
	EndTime        int64  `json:"end_time"`
	EventType      string `json:"event_type"`
	EventContent   any    `json:"event_content"`
	ServiceName    string `json:"service_name"`
	EnvInformation string `json:"env_information"`
	StatusCode     int    `json:"status_code"`
}
