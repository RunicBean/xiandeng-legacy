package gql_errcode

import (
	"github.com/vektah/gqlparser/v2/gqlerror"
	errcode "xiandeng.net.cn/server/errors"
)

func GqlError(err errcode.Error) error {
	return &gqlerror.Error{
		Message: err.Msg,
		Extensions: map[string]interface{}{
			"code": err.Code,
		},
	}
}
