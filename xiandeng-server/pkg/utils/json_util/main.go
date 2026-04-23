package jsonutil

import (
	"encoding/json"
	"strings"
	"time"
)

type GeneralDate time.Time

func (d *GeneralDate) UnmarshalJSON(b []byte) error {
	s := strings.Trim(string(b), "\"")
	t, err := time.Parse("2006-01-02", s)
	if err != nil {
		return err
	}
	*d = GeneralDate(t)
	return nil
}

func (d GeneralDate) MarshalJSON() ([]byte, error) {
	return json.Marshal(time.Time(d))
}

// Maybe a Format function for printing your date
func (d GeneralDate) Format(s string) string {
	t := time.Time(d)
	return t.Format(s)
}
