package scraper

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
)

type ParseFunc func(*http.Response) (any, error)

type FormData map[string]string

type Scraper struct {
	targetUrl string
	method    string

	datas    FormData
	withData bool

	jsonStr  string
	withJson bool

	ctx         context.Context
	withContext bool

	headers     map[string]string
	withHeaders bool

	parser   ParseFunc
	response *http.Response
}

func (s *Scraper) AddHeaders(hs map[string]string) {
	if s.headers == nil {
		s.headers = hs
	} else {
		for k, v := range hs {
			s.headers[k] = v
		}
	}
	s.withHeaders = true
}

func (s *Scraper) AddHeader(k, v string) {
	if s.headers == nil {
		s.headers = make(map[string]string)
	}
	s.headers[k] = v
	s.withHeaders = true
}

func (s *Scraper) SetTargetUrl(url string, method string) {
	s.targetUrl = url
	s.method = method
}

type Option func(s *Scraper)

func WithData(datas FormData) Option {
	return func(s *Scraper) {
		s.datas = datas
		s.withData = true
	}
}

func WithJson(jsonStr string) Option {
	return func(s *Scraper) {
		s.jsonStr = jsonStr
		s.withJson = true
	}

}

func WithContext(ctx context.Context) Option {
	return func(s *Scraper) {
		s.ctx = ctx
		s.withContext = true
	}
}

func WithBearerToken(token string) Option {
	return func(s *Scraper) {
		s.AddHeader("Authorization", fmt.Sprintf("Bearer %s", token))
	}
}

func (s *Scraper) Scrape(options ...Option) error {
	for _, opt := range options {
		opt(s)
	}

	var resp *http.Response
	var err error
	var req *http.Request

	if !s.withContext {
		req, err = http.NewRequestWithContext(context.Background(), s.method, s.targetUrl, nil)
	} else {
		req, err = http.NewRequestWithContext(s.ctx, s.method, s.targetUrl, nil)
	}
	if err != nil {
		fmt.Printf("failed to create request: %s\n", err.Error())
		return fmt.Errorf("failed to create request: %s", err.Error())
	}

	if s.withData {
		formData := url.Values{}
		for k, v := range s.datas {
			formData.Set(k, v)
		}
		req.Body = io.NopCloser(strings.NewReader(formData.Encode()))
		req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	}

	if s.withHeaders {
		for k, v := range s.headers {
			req.Header.Add(k, v)
		}
	}

	if s.withJson {
		req.Header.Add("Content-Type", "application/json")
		req.Body = io.NopCloser(bytes.NewBuffer([]byte(s.jsonStr)))
	}

	resp, err = http.DefaultClient.Do(req)

	if err != nil {
		fmt.Printf("http client do error: %s\n", err.Error())
		return err
	}
	if resp.StatusCode != 200 {
		b, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("status code error: %d %s, %s", resp.StatusCode, resp.Status, b)
	}

	s.response = resp
	return err
}

func (s *Scraper) SetParser(f ParseFunc) {
	s.parser = f
}

func (s *Scraper) Parse() (any, error) {
	defer s.response.Body.Close()
	if s.parser == nil {
		return nil, fmt.Errorf("parser should be set first")
	}
	parsed, err := s.parser(s.response)
	return parsed, err
}
