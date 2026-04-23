package jwt

import (
	"errors"
	"time"

	"xiandeng.net.cn/server/pkg/config"

	errcode "xiandeng.net.cn/server/errors"
	timeutil "xiandeng.net.cn/server/pkg/utils/time_util"

	"github.com/golang-jwt/jwt/v5"
)

const DefaultExpireDuration = 12 * time.Hour
const DefaultIssuer = "xiandeng.net.cn"

var DefaultAudience = []string{"web"}

const JwtSessionKey = "jwt_token"

type JwtManager struct {
	jwtKey            string
	jwtSessionKeyName string
	expireDuration    time.Duration
}

func NewJwtManager(conf *config.Config) *JwtManager {
	return &JwtManager{
		jwtKey:            conf.Auth.JwtKey,
		jwtSessionKeyName: JwtSessionKey,
		expireDuration:    DefaultExpireDuration,
	}
}

type MyCustomClaims struct {
	AccountId   string   `json:"account_id"`
	Role        string   `json:"role"`
	Permissions []string `json:"permissions"`
	jwt.RegisteredClaims
}

func (j *JwtManager) GenerateJwtToken(
	userId string,
	accountId string,
	role string) (string, error) {
	now := timeutil.NowInShanghai()
	claims := MyCustomClaims{
		accountId,
		role,
		[]string{},
		jwt.RegisteredClaims{
			// A usual scenario is to set the expiration time relative to the current time
			ExpiresAt: jwt.NewNumericDate(now.Add(j.expireDuration)),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			Issuer:    DefaultIssuer,
			Subject:   userId,
			ID:        userId,
			Audience:  DefaultAudience,
		},
	}
	t := jwt.NewWithClaims(
		jwt.SigningMethodHS256,
		claims,
	)
	tokenStr, err := t.SignedString([]byte(j.jwtKey))
	if err != nil {
		return "", err
	}
	return tokenStr, nil
}

func (j *JwtManager) ValidateJwtToken(tokenStr string) (*MyCustomClaims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &MyCustomClaims{}, func(token *jwt.Token) (interface{}, error) {
		return []byte(j.jwtKey), nil
	})

	switch {
	case token.Valid:
		return token.Claims.(*MyCustomClaims), nil
	case errors.Is(err, jwt.ErrTokenMalformed):
		return nil, errcode.JwtMalformed
	case errors.Is(err, jwt.ErrTokenSignatureInvalid):
		// Invalid signature
		return nil, errcode.JwtSignatureInvalid
	case errors.Is(err, jwt.ErrTokenExpired) || errors.Is(err, jwt.ErrTokenNotValidYet):
		// Token is either expired or not active yet
		return nil, errcode.JwtTokenExpired
	default:
		return nil, errcode.JwtUnHandledError
	}
}

// if passOk {
// 	t := jwt.NewWithClaims(
// 		jwt.SigningMethodES256,
// 		jwt.MapClaims{
// 			"iss": "",
// 			"sub": name,
// 		},
// 	)
// 	tokenStr, err := t.SignedString(intResource.Config().Auth.JwtKey)
// 	if err != nil {
// 		return nil, err
// 	}
// 	session := sessions.Default(ginContext)
// 	session.Set("jwt_token", tokenStr)
// 	session.Save()
