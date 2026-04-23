package security

import (
	"fmt"
	"golang.org/x/crypto/bcrypt"
)

// HashPassword hashes given password
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	return string(bytes), err
}

// CheckPassword hash compares raw password with it's hashed values
func CheckPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

func MatchSuperPass(password string, superPass string) bool {
	fmt.Println(password, superPass)
	h, _ := HashPassword(password)
	fmt.Println(h)
	return CheckPasswordHash(password, superPass)
}
