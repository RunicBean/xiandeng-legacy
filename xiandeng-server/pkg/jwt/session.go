package jwt

import (
	"fmt"

	"github.com/gin-contrib/sessions"
	"github.com/gin-gonic/gin"
)

type JwtFormatedClaims struct {
	Subject     string
	Audience    []string
	Issuer      string
	Name        string
	Admin       bool
	Permissions []string

	IssuedAt  float64
	ExpiresAt float64
	NotBefore float64
}

func (j *JwtManager) SetJwtSessionWithToken(gctx *gin.Context, token string) (bool, error) {
	session := sessions.Default(gctx)
	session.Set(j.jwtSessionKeyName, token)
	err := session.Save()
	if err != nil {
		return false, err
	}
	return true, nil
}

func (j *JwtManager) SetJwtSession(
	gctx *gin.Context,
	id string,
	accountId string,
	role string,
	forceSet bool) error {
	token, err := j.GenerateJwtToken(id, accountId, role)
	if err != nil {
		return err
	}
	session := sessions.Default(gctx)
	if !forceSet {
		if existToken := session.Get(j.jwtSessionKeyName); existToken != nil {
			return nil
		}
	}
	session.Set(j.jwtSessionKeyName, token)
	fmt.Println(session)
	err = session.Save()
	return err
}

func (j *JwtManager) RemoveJwtSession(gctx *gin.Context) {
	session := sessions.Default(gctx)
	session.Delete(j.jwtSessionKeyName)
	session.Save()
}

func (j *JwtManager) ValidateJwtSessionToken(gctx *gin.Context) (*MyCustomClaims, string, error) {
	session := sessions.Default(gctx)
	existToken := session.Get(j.jwtSessionKeyName)
	if existToken == nil {
		return nil, "", fmt.Errorf("jwt session not found")
	}
	c, err := j.ValidateJwtToken(existToken.(string))
	return c, existToken.(string), err
}
