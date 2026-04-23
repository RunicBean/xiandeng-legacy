package web

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"net/http"
)

type HttpRequestOptions struct {
	Method     string
	Url        string
	Parameters map[string]string
	Data       interface{}
	Headers    map[string]string
}

// BasicAuth encode string like `username:password` to
// base64 encoded format, for Basic Authentication.
//
// After encoding base64 format, add it to header like
// `Authorization: "Basic <base64 string>"`
func BasicAuth(username, password string) string {
	auth := username + ":" + password
	return base64.StdEncoding.EncodeToString([]byte(auth))
}

// AddParams function add queries/params to http.Request, like "http://example.com/test?key=value"
func AddParams(req *http.Request, params map[string]string) {
	q := req.URL.Query()
	for k, v := range params {
		q.Add(k, v)
	}
	req.URL.RawQuery = q.Encode()
}

func AddHeaders(req *http.Request, headers map[string][]string) {
	if headers == nil {
		return
	}
	for k, v := range headers {
		for _, value := range v {
			req.Header.Add(k, value)
		}
	}
}

func HTTPRequest(method string, url string, params map[string]string, data interface{}, headers map[string][]string) *http.Response {
	client := &http.Client{}
	var req *http.Request

	if data != nil {
		dataBytes, _ := json.Marshal(data)
		req, _ = http.NewRequest(method, url, bytes.NewReader(dataBytes))
	} else {
		req, _ = http.NewRequest(method, url, nil)
	}
	AddParams(req, params)
	AddHeaders(req, headers)

	resp, _ := client.Do(req)
	return resp
}

func ParseResponse(response *http.Response, jsonStructure interface{}) {

}

type JsonResult struct {
	ErrorCode int         `json:"errorCode"`
	Message   string      `json:"message"`
	Data      interface{} `json:"data"`
	Success   bool        `json:"success"`
	Total     int         `json:"total"`
}

func Json(code int, message string, data interface{}, success bool) *JsonResult {
	return &JsonResult{
		ErrorCode: code,
		Message:   message,
		Data:      data,
		Success:   success,
	}
}

func JsonData(data interface{}) *JsonResult {
	return &JsonResult{
		ErrorCode: 0,
		Data:      data,
		Success:   true,
	}
}
