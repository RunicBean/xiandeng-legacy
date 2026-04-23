package scraper

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"xiandeng.net.cn/server/constants"
)

type RecruitItem struct {
	Content         string `json:"content"`
	Url             string `json:"url"`
	BeginTime       string `json:"beginTime"`
	EndTime         string `json:"endTime"`
	OverseasStudent string `json:"overseasStudent"`
	DomesticStudent string `json:"domesticStudent"`
	RichText        string `json:"richText"`
	ReleaseSource   string `json:"releaseSource"`
}

type RecruitItemResponse struct {
	Success bool        `json:"success"`
	Data    RecruitItem `json:"data"`
	Message string      `json:"message"`
}

func (ris *RecruitItemScraper) SetUp() {
	ris.SetParser(func(r *http.Response) (any, error) {
		var recruitItem RecruitItemResponse
		body, err := io.ReadAll(r.Body)
		if err != nil {
			return nil, fmt.Errorf("failed to read response body: %s", err.Error())
		}
		err = json.Unmarshal(body, &recruitItem)
		if err != nil {
			return nil, err
		}
		if !recruitItem.Success {
			return nil, fmt.Errorf("scrape: %v", recruitItem.Message)
		}
		return recruitItem.Data, nil
	})
}

type RecruitItemScraper struct {
	Scraper
}

func (rs *RecruitItemScraper) ScrapeAndParse(recruitId int) (any, error) {
	rs.SetTargetUrl(fmt.Sprintf("%s%d", constants.RECRUIT_ITEM_URL, recruitId), http.MethodGet)
	err := rs.Scrape()
	if err != nil {
		return nil, err
	}

	data, err := rs.Parse()
	if err != nil {
		return nil, err
	}
	return data, nil
}

func NewRecruitItemScraper() *RecruitItemScraper {
	rs := &RecruitItemScraper{}
	rs.AddHeaders(map[string]string{
		"Host": "backservice.offerxiansheng.com",
	})
	rs.SetUp()
	return rs
}
