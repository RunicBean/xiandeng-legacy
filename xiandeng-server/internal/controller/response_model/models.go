package response_model

// `Time` is a simple type only containing the current time as
// a unix epoch timestamp and a string timestamp.
type Time struct {
	UnixTime  int    `json:"unixTime"`
	TimeStamp string `json:"timeStamp"`
}
