package scraper

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

type AiResult struct {
	Answer string `json:"answer"`
}

func (ris *StudentSuggestionScraper) SetUp() {
	ris.SetParser(func(r *http.Response) (any, error) {
		var aiResult AiResult
		body, err := io.ReadAll(r.Body)
		if err != nil {
			return nil, fmt.Errorf("failed to read response body: %s", err.Error())
		}
		err = json.Unmarshal(body, &aiResult)
		if err != nil {
			return nil, err
		}
		return aiResult, nil
	})
}

type StudentSuggestionScraper struct {
	Scraper
	llmAPIKey string
	targetUrl string
}

type StudentSuggestionInputs struct {
	Name   string `json:"name"`
	Sex    string `json:"sex"`
	Major  string `json:"major"`
	School string `json:"school"`
	MBTI   string `json:"mbti"`
}

type StudentSuggestionScrapeBody struct {
	AccountId    string                  `json:"account_id"`
	Inputs       StudentSuggestionInputs `json:"inputs"`
	ResponseMode string                  `json:"response_mode"`
	User         string                  `json:"user"`
}

//var targetUrl = "http://34.81.61.38/v1/completion-messages"

func (rs *StudentSuggestionScraper) ScrapeAndParse(ctx context.Context, body StudentSuggestionScrapeBody) (any, error) {
	rs.SetTargetUrl(rs.targetUrl, http.MethodPost)
	jsonBytes, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}
	err = rs.Scrape(
		WithJson(string(jsonBytes)),
		WithContext(ctx),
		WithBearerToken(rs.llmAPIKey),
	)
	if err != nil {
		return nil, err
	}

	data, err := rs.Parse()
	if err != nil {
		return nil, err
	}
	return data, nil
}

func NewStudySuggestionScraper(targetUrl string) *StudentSuggestionScraper {
	rs := &StudentSuggestionScraper{targetUrl: targetUrl}
	rs.SetUp()
	return rs
}
