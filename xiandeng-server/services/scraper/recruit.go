package scraper

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"xiandeng.net.cn/server/constants"
)

type Recruit struct {
	RecruitId      int          `json:"recruitId"`
	CompanyName    string       `json:"companyName"`
	EnterpriseName string       `json:"enterpriseName"`
	LogoUrl        *string      `json:"logoUrl"`
	CityNameList   string       `json:"cityNameList"`
	UpdateTime     string       `json:"updateTime"`
	CompanyType    string       `json:"companyType"`
	EndTime        *string      `json:"endTime"`
	Tag            string       `json:"tag"`
	IsRecommend    int          `json:"isRecommend"`
	Item           *RecruitItem `json:"item"`
}

type RecruitScraper struct {
	Scraper
}

type RecruitRequestBody struct {
	Id          int    `json:"id"`
	Page        int    `json:"page"`
	Size        int    `json:"size"`
	Order       string `json:"order"`
	CityIdList  string `json:"cityIdList"`
	CompanyType string `json:"companyType"`
	Day         string `json:"day"`
}

type RecruitResponse struct {
	Success bool `json:"success"`
	Data    struct {
		Records []*Recruit `json:"records"`
	} `json:"data"`
	Message string `json:"message"`
}

func (rs *RecruitScraper) SetUp() {
	rs.SetParser(func(r *http.Response) (any, error) {
		var recruit RecruitResponse
		body, err := io.ReadAll(r.Body)
		if err != nil {
			return nil, fmt.Errorf("failed to read response body: %s", err.Error())
		}
		err = json.Unmarshal(body, &recruit)
		if err != nil {
			return nil, err
		}
		if !recruit.Success {
			return nil, fmt.Errorf("scrape: %v", recruit.Message)
		}
		return recruit.Data.Records, nil
	})
}

func (rs *RecruitScraper) ScrapeAndParse(page int, size int) ([]*Recruit, error) {
	var body = RecruitRequestBody{
		Id:          11, // 固定，代表offer先生里面的国央企
		Page:        page,
		Size:        size,
		Order:       "UPDATE_TIME",
		CityIdList:  "",
		CompanyType: "", // 央企/国企
		Day:         "",
	}
	jsonStr, _ := json.Marshal(body)
	err := rs.Scrape(WithJson(string(jsonStr)))
	if err != nil {
		return nil, err
	}

	data, err := rs.Parse()
	if err != nil {
		return nil, err
	}
	if data == nil {
		fmt.Println("Recruit result is nil!")
		return nil, err
	}

	ris := NewRecruitItemScraper()
	for _, d := range data.([]*Recruit) {
		ri, err := ris.ScrapeAndParse(d.RecruitId)
		if err != nil {
			fmt.Printf("RecruitItem Scrape interrupted: %v\n", err.Error())
			return nil, err
		}
		item := ri.(RecruitItem)
		d.Item = &item
	}
	return data.([]*Recruit), nil
}

func NewRecruitScraper() *RecruitScraper {
	rs := &RecruitScraper{}
	rs.SetTargetUrl(constants.RECRUIT_URL, http.MethodPost)
	rs.AddHeaders(map[string]string{
		"Host": "backservice.offerxiansheng.com",
	})
	rs.SetUp()
	return rs
}
