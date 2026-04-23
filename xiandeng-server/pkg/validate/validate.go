package validate

import (
	"regexp"

	"github.com/go-playground/validator/v10"
)

var (
	validate *validator.Validate
)

func NewValidator() *validator.Validate {
	if validate == nil {
		validate = validator.New()
		validate.RegisterValidation("card-number", ValidateBankAccountNumber)
	}
	return validate
}

// ValidateValuer implements validator.CustomTypeFunc
func ValidateBankAccountNumber(fl validator.FieldLevel) bool {
	acctNumber := fl.Field().String()
	re := regexp.MustCompile(`^\d{16,19}$`)
	ok := re.MatchString(acctNumber)
	return ok
}
