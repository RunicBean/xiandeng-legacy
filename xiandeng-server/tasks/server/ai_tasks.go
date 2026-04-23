package server

import (
	"context"
	"fmt"
	"log"

	"github.com/google/uuid"
	"github.com/wechatpay-apiv3/wechatpay-go/core"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/services/scraper"
)

func (ts *taskServer) UpdateStudySuggestion(
	ctx context.Context,
	accountId string,
	name string,
	sex string,
	major string,
	school string,
	mbti string,
) (string, error) {
	log.Printf("UpdateStudySuggestion: user_acct_id=%s", accountId)
	acctUUID, err := uuid.Parse(accountId)

	if err != nil {
		return "", fmt.Errorf("invalid accountid, should be UUID: %s", accountId)
	}

	queries := ts.repository.NewQueries()

	// 初始化pending状态
	queries.UpdateStudentStudySuggestion(ctx, models.UpdateStudentStudySuggestionParams{
		Accountid:       acctUUID,
		Studysuggestion: core.String("pending"),
	})

	s := scraper.NewStudySuggestionScraper(ts.conf.Server.ProductDomain + "/llm/student/suggestion/update")
	_, err = s.ScrapeAndParse(ctx, scraper.StudentSuggestionScrapeBody{
		AccountId: accountId,
		Inputs: scraper.StudentSuggestionInputs{
			School: school,
			MBTI:   mbti,
			Name:   name,
			Sex:    sex,
			Major:  major,
		},
		ResponseMode: "blocking",
		User:         "user",
	})
	if err != nil {
		return "", fmt.Errorf("scrape and parse study suggestion: %s", err.Error())
	}

	return "done", nil
}
