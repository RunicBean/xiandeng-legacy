package utils

import (
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
)

func TimeStringToPgtypeTimestamp(s *string, format string) *pgtype.Timestamp {
	if s == nil || *s == "" {
		return &pgtype.Timestamp{Valid: false}
	}
	upt, err := time.Parse(format, *s)
	if err != nil {
		panic(fmt.Errorf("TimeStringToPgtypeTimestamp parse string: %s with format: %s error: %s", *s, format, err.Error()))
	}
	uptt := new(pgtype.Timestamp)
	err = uptt.Scan(upt)
	if err != nil {
		panic(fmt.Errorf("TimeStringToPgtypeTimestamp scan: %s", err.Error()))
	}
	return uptt
}

func TimeStringToPgtypeDate(s *string, format string) *pgtype.Date {
	if s == nil || *s == "" {
		return &pgtype.Date{Valid: false}
	}
	upt, err := time.Parse(format, *s)
	if err != nil {
		panic(fmt.Errorf("TimeStringToPgtypeTimestamp parse string: %s with format: %s error: %s", *s, format, err.Error()))
	}
	uptt := new(pgtype.Date)
	err = uptt.Scan(upt)
	if err != nil {
		panic(fmt.Errorf("TimeStringToPgtypeTimestamp scan: %s", err.Error()))
	}
	return uptt
}

func PgDateToTimeString(d pgtype.Date) string {
	if !d.Valid {
		return ""
	}
	return d.Time.Format("2006-01-02")
}
