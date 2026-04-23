package product

import (
	"context"
	"fmt"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/pkg/utils/model_util"

	"xiandeng.net.cn/server/services/scraper"
)

func UpdateRecruit(r db.Repository) {
	q := r.NewQueries()
	fmt.Println("start recruit parsing.")
	rs := scraper.NewRecruitScraper()
	data, err := rs.ScrapeAndParse(1, 50)
	if err != nil {
		fmt.Printf("scrape and parse recruit error: %s\n", err.Error())
		return
	}

	newdata := make([]*scraper.Recruit, 0)
	for _, d := range data {
		e, _ := q.CheckRecruitIdExists(context.Background(), int32(d.RecruitId))
		if !e {
			newdata = append(newdata, d)
		}
	}

	count, err := q.InsertRecruits(context.Background(), model_util.RecruitInsertParamsTransform(newdata))
	if err != nil {
		fmt.Printf("insert recruit data error: %s\n", err.Error())
		return
	}

	fmt.Printf("updated recruit records: %d\n", count)

}
