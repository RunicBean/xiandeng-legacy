package request_model

type MbtiData struct {
	MbtiEnergy   string `json:"mbtiEnergy" form:"mbtiEnergy"`
	MbtiMind     string `json:"mbtiMind" form:"mbtiMind"`
	MbtiDecision string `json:"mbtiDecision" form:"mbtiDecision"`
	MbtiReaction string `json:"mbtiReaction" form:"mbtiReaction"`
}

func (mbtiData MbtiData) Concat() string {
	return mbtiData.MbtiEnergy + mbtiData.MbtiMind + mbtiData.MbtiDecision + mbtiData.MbtiReaction
}

type GaokaoData struct {
	TotalScore      *float64 `json:"totalScore" form:"totalScore"`
	Chinese         *float64 `json:"chinese" form:"chinese"`
	Mathematics     *float64 `json:"mathematics" form:"mathematics"`
	ForeignLanguage *float64 `json:"foreignLanguage" form:"foreignLanguage"`
	Physics         *float64 `json:"physics" form:"physics"`
	Chemistry       *float64 `json:"chemistry" form:"chemistry"`
	Biology         *float64 `json:"biology" form:"biology"`
	History         *float64 `json:"history" form:"history"`
	Politics        *float64 `json:"politics" form:"politics"`
	Geography       *float64 `json:"geography" form:"geography"`
}

type BodyUpdateStudentProfile struct {
	FirstName   string     `json:"firstname" form:"firstname"`
	LastName    string     `json:"lastname" form:"lastname"`
	Sex         string     `json:"sex" form:"sex"`
	University  string     `json:"university" form:"university"`
	MajorCode   string     `json:"majorcode" form:"majorcode"`
	MajorType   string     `json:"majortype" form:"majortype"`
	EntryDate   *string    `json:"entrydate" form:"entrydate"`
	DegreeYears *int16     `json:"degreeyears" form:"degreeyears"`
	MbtiData    MbtiData   `json:"mbtiForm" form:"mbtiForm"`
	GaokaoData  GaokaoData `json:"gaokaoForm" form:"gaokaoForm"`
}
