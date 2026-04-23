package tests

import (
	"flag"
	"fmt"
	"testing"

	"github.com/google/uuid"
	. "gopkg.in/check.v1"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/pkg/security"
	"xiandeng.net.cn/server/pkg/wechat"
)

// Hook up check.v1 into go test
func TestSignup(t *testing.T) {
	TestingT(t)
}

type SignupSuite struct{}

var _ = Suite(&SignupSuite{})

var signupConfString = flag.String("conf", "", "config file path. i.e. -conf conf/local_config.yaml")

func (s *SignupSuite) SetUpSuite(c *C) {
	flag.Parse()
	fmt.Println("Signup test suite starting...")
}

// ============================================================================
// Password Hashing Tests
// ============================================================================

func (s *SignupSuite) TestSignup_PasswordHashing_Correct(c *C) {
	password := "TestPassword123"
	hash, err := security.HashPassword(password)

	c.Assert(err, IsNil)
	c.Assert(hash, Not(Equals), "")
	c.Assert(hash, Not(Equals), password)
}

func (s *SignupSuite) TestSignup_PasswordHashing_Verification(c *C) {
	password := "TestPassword123"
	hash, err := security.HashPassword(password)
	c.Assert(err, IsNil)

	result := security.CheckPasswordHash(password, hash)
	c.Assert(result, Equals, true)
}

func (s *SignupSuite) TestSignup_PasswordHashing_WrongPassword(c *C) {
	password := "TestPassword123"
	wrongPassword := "WrongPassword456"
	hash, err := security.HashPassword(password)
	c.Assert(err, IsNil)

	result := security.CheckPasswordHash(wrongPassword, hash)
	c.Assert(result, Equals, false)
}

func (s *SignupSuite) TestSignup_PasswordHashing_DifferentHashes(c *C) {
	password := "TestPassword123"
	hash1, err := security.HashPassword(password)
	c.Assert(err, IsNil)
	hash2, err := security.HashPassword(password)
	c.Assert(err, IsNil)

	// Same password should produce different hashes (due to bcrypt salting)
	c.Assert(hash1, Not(Equals), hash2)

	// But both should verify correctly
	c.Assert(security.CheckPasswordHash(password, hash1), Equals, true)
	c.Assert(security.CheckPasswordHash(password, hash2), Equals, true)
}

// ============================================================================
// Phone Validation Tests
// ============================================================================

func (s *SignupSuite) TestSignup_PhoneValidation_Valid(c *C) {
	validPhones := []string{
		"13812345678",
		"15912345678",
		"18612345678",
		"19812345678",
	}

	for _, phone := range validPhones {
		c.Assert(isValidPhone(phone), Equals, true, Commentf("Phone %s should be valid", phone))
	}
}

func (s *SignupSuite) TestSignup_PhoneValidation_TooShort(c *C) {
	phone := "1381234567" // 10 digits, too short
	c.Assert(isValidPhone(phone), Equals, false)
}

func (s *SignupSuite) TestSignup_PhoneValidation_TooLong(c *C) {
	phone := "138123456789" // 12 digits, too long
	c.Assert(isValidPhone(phone), Equals, false)
}

func (s *SignupSuite) TestSignup_PhoneValidation_InvalidPrefix(c *C) {
	phones := []string{
		"22812345678", // starts with 2
		"00812345678", // starts with 0
	}
	for _, phone := range phones {
		c.Assert(isValidPhone(phone), Equals, false, Commentf("Phone %s should be invalid", phone))
	}
}

func (s *SignupSuite) TestSignup_PhoneValidation_NonNumeric(c *C) {
	phones := []string{
		"1381234567a",
		"13812345678a",
		"138123456!@",
		"abcdefghijk",
	}
	for _, phone := range phones {
		c.Assert(isValidPhone(phone), Equals, false, Commentf("Phone %s should be invalid", phone))
	}
}

// ============================================================================
// RegisterUserParams Tests
// ============================================================================

func (s *SignupSuite) TestSignup_RegisterUserParams_Valid(c *C) {
	phone := "13812345678"
	password := "TestPassword123"
	hashedPassword, err := security.HashPassword(password)
	c.Assert(err, IsNil)

	params := models.RegisterUserParams{
		UPhone:    phone,
		NickName: "TestUser",
		OpenID:    "test_open_id_123",
		UPassword: hashedPassword,
		USource:   "test",
	}

	c.Assert(params.UPhone, Equals, phone)
	c.Assert(params.UPassword, Equals, hashedPassword)
	c.Assert(params.UPassword, Not(Equals), password) // Password should be hashed
}

func (s *SignupSuite) TestSignup_RegisterUserParams_WithOptionalFields(c *C) {
	email := "test@example.com"
	accountName := "TestAccount"
	invitationCode := "TEST123"

	params := models.RegisterUserParams{
		UPhone:         "13812345678",
		NickName: "TestUser",
		OpenID:        "test_open_id_123",
		UPassword:     "hashed_password",
		USource:       "test",
		UEmail:        &email,
		AccountName:   &accountName,
		InvitationCode: &invitationCode,
	}

	c.Assert(*params.UEmail, Equals, email)
	c.Assert(*params.AccountName, Equals, accountName)
	c.Assert(*params.InvitationCode, Equals, invitationCode)
}

// ============================================================================
// RegisterUserRow Tests
// ============================================================================

func (s *SignupSuite) TestSignup_RegisterUserRow_Fields(c *C) {
	accountID := uuid.New()
	row := models.RegisterUserRow{
		Userid:      "user_123",
		Accountid:   accountID,
		AccountType: models.RoletypeSTUDENT,
		UserRole:    "student",
	}

	c.Assert(row.Userid, Equals, "user_123")
	c.Assert(row.Accountid, Equals, accountID)
	c.Assert(row.AccountType, Equals, models.RoletypeSTUDENT)
	c.Assert(row.UserRole, Equals, "student")
}

// ============================================================================
// Mock WeChat Service Tests
// ============================================================================

func (s *SignupSuite) TestSignup_MockWechatService_GetAppId(c *C) {
	mock := &mockWechatService{
		mockAppId: "test_app_id_123",
	}

	c.Assert(mock.GetAppId(), Equals, "test_app_id_123")
}

func (s *SignupSuite) TestSignup_MockWechatService_CodeExchange(c *C) {
	mock := &mockWechatService{
		mockOpenID: "mock_open_id_123",
	}

	token, err := mock.CodeExchange("test_code")
	c.Assert(err, IsNil)
	c.Assert(token.OpenID, Equals, "mock_open_id_123")
}

func (s *SignupSuite) TestSignup_MockWechatService_GetUserInfoWithCode(c *C) {
	mock := &mockWechatService{
		mockOpenID:       "mock_open_id_456",
		mockNickName:     "MockUser",
		mockHeadImageURL: "https://example.com/avatar.jpg",
	}

	userInfo, err := mock.GetUserInfoWithCode("test_code")
	c.Assert(err, IsNil)
	c.Assert(userInfo.OpenID, Equals, "mock_open_id_456")
	c.Assert(userInfo.NickName, Equals, "MockUser")
	c.Assert(userInfo.HeadImageUrl, Equals, "https://example.com/avatar.jpg")
}

// ============================================================================
// Helper Functions and Mocks
// ============================================================================

// isValidPhone validates Chinese mobile phone numbers (11 digits starting with 1)
func isValidPhone(phone string) bool {
	if len(phone) != 11 {
		return false
	}
	if phone[0] != '1' {
		return false
	}
	for _, c := range phone {
		if c < '0' || c > '9' {
			return false
		}
	}
	return true
}

// strPtr is a helper to create string pointers
func strPtr(s string) *string {
	return &s
}

// mockWechatService implements wechat.WechatService for testing
type mockWechatService struct {
	mockAppId       string
	mockOpenID      string
	mockNickName    string
	mockHeadImageURL string
}

func (m *mockWechatService) GetAppId() string {
	return m.mockAppId
}

func (m *mockWechatService) CodeExchange(code string) (*wechat.AccessTokenResponse, error) {
	return &wechat.AccessTokenResponse{
		AccessToken: "test_token_" + code,
		OpenID:      m.mockOpenID,
	}, nil
}

func (m *mockWechatService) GetUserInfo(accessToken string, openID string) (*wechat.WxUserInfo, error) {
	return &wechat.WxUserInfo{
		OpenID:       m.mockOpenID,
		NickName:     m.mockNickName,
		HeadImageUrl: m.mockHeadImageURL,
	}, nil
}

func (m *mockWechatService) GetUserInfoWithCode(code string) (*wechat.WxUserInfo, error) {
	return &wechat.WxUserInfo{
		OpenID:       m.mockOpenID,
		NickName:     m.mockNickName,
		HeadImageUrl: m.mockHeadImageURL,
	}, nil
}

// Ensure mockWechatService implements wechat.WechatService
var _ wechat.WechatService = (*mockWechatService)(nil)

// ============================================================================
// Integration Test Helpers (require DB/cache - skip in unit tests)
// ============================================================================

// createTestRegisterUserParams creates a valid RegisterUserParams for testing
func createTestRegisterUserParams(phone, password, openID string) models.RegisterUserParams {
	hashedPassword, _ := security.HashPassword(password)
	return models.RegisterUserParams{
		UPhone:    phone,
		NickName: "TestUser",
		OpenID:    openID,
		UPassword: hashedPassword,
		USource:   "test",
	}
}

// generateTestSessionID creates a UUID session ID for testing
func generateTestSessionID() string {
	return uuid.New().String()
}

// createMockWxUserInfo creates a mock WxUserInfo for testing
func createMockWxUserInfo(openID, nickName string) *wechat.WxUserInfo {
	return &wechat.WxUserInfo{
		OpenID:       openID,
		NickName:     nickName,
		HeadImageUrl: "https://example.com/avatar.jpg",
	}
}

// assertPasswordHashed verifies that the password is hashed and not plaintext
func assertPasswordHashed(c *C, password, storedValue string) {
	c.Assert(storedValue, Not(Equals), password)
	c.Assert(len(storedValue) > 20, Equals, true) // bcrypt hashes are typically > 20 chars
}

// validateRegisterUserParams validates RegisterUserParams for testing
func validateRegisterUserParams(params models.RegisterUserParams) error {
	if params.UPhone == "" {
		return fmt.Errorf("phone is required")
	}
	if !isValidPhone(params.UPhone) {
		return fmt.Errorf("invalid phone format")
	}
	if params.UPassword == "" {
		return fmt.Errorf("password is required")
	}
	if len(params.UPassword) < 20 {
		return fmt.Errorf("password appears to be plaintext (not hashed)")
	}
	if params.OpenID == "" {
		return fmt.Errorf("openID is required")
	}
	return nil
}
