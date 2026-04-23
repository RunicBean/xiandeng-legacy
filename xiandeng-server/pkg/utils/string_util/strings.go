package string_util

import (
	"math/rand"
	"strconv"
	"strings"

	timeutil "xiandeng.net.cn/server/pkg/utils/time_util"
)

func RandomString(length int) string {
	r := rand.New(rand.NewSource(timeutil.NowInShanghai().Unix()))

	var output strings.Builder

	charSet := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJULMNOPQRSTUVWXYZ0123456789"
	for i := 0; i < length; i++ {
		random := r.Intn(len(charSet))
		randomChar := charSet[random]
		output.WriteString(string(randomChar))
	}
	return (output.String())
}

func RandomNumber(length int) string {
	r := rand.New(rand.NewSource(timeutil.NowInShanghai().Unix()))

	var output strings.Builder

	charSet := "123456789"
	for i := 0; i < length; i++ {
		random := r.Intn(len(charSet))
		randomChar := charSet[random]
		output.WriteString(string(randomChar))
	}
	return (output.String())
}

func RandomNumberInt64(length int) int64 {
	n, _ := strconv.Atoi(RandomNumber(length))
	return int64(n)
}

func ConvertStringPtr(p *string) string {
	if p == nil {
		return ""
	}
	return *p
}
