package utils

func Int32Pointer(i int) *int32 {
	var ret = int32(i)
	return &ret
}

func StringPointer(s string) *string {
	var ret = s
	return &ret
}

func PtrToFloat64(p *float64) float64 {
	if p == nil {
		return 0
	}
	return *p
}
