package timeutil

import "time"

func NowInShanghai() time.Time {
	shanghaiLocation, _ := time.LoadLocation("Asia/Shanghai")
	return time.Now().In(shanghaiLocation)
}

func TimeInShanghai(t time.Time) time.Time {
	shanghaiLocation, _ := time.LoadLocation("Asia/Shanghai")
	return t.In(shanghaiLocation)
}
