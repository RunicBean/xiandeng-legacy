package response_model

import "xiandeng.net.cn/server/internal/code"

type User struct {
	ID          string     `json:"id"`
	NickName    string     `json:"nick_name"`
	AliasName   *string    `json:"alias_name"`
	Phone       string     `json:"phone"`
	AvatarURL   *string    `json:"avatar_url"`
	AccountId   string     `json:"account_id"`
	AccountName string     `json:"account_name"`
	AgentCheck  *code.Code `json:"agent_check"`
	DemoMode    bool       `json:"demo_mode"`
}
