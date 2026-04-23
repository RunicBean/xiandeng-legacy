package controller

type ResponseJsonResult struct {
	ErrorCode int         `json:"errorCode"`
	Message   string      `json:"message"`
	Data      interface{} `json:"data"`
	Success   bool        `json:"success"`
}

type RespDataUser struct {
	ID            string  `json:"id"`
	Password      string  `json:"password"`
	Phone         string  `json:"phone"`
	Email         *string `json:"email"`
	Nickname      string  `json:"nickname"`
	Firstname     *string `json:"firstname"`
	Lastname      *string `json:"lastname"`
	Wechatopenid  *string `json:"wechatopenid"`
	Wechatunionid *string `json:"wechatunionid"`
	Sex           string  `json:"sex" enums:"0,1"`
	Province      *string `json:"province"`
	City          *string `json:"city"`
	Birthdate     string  `json:"birthdate"`
	Avatarurl     *string `json:"avatarurl"`
	Status        string  `json:"status"`
	Source        *string `json:"source"`
	Accountid     string  `json:"accountid"`
	Referaluserid string  `json:"referaluserid"`
	Createdat     string  `json:"createdat"`
	Updatedat     string  `json:"updatedat"`
}
