package services

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/jackc/pgx/v5/pgtype"
	"go.uber.org/zap"
	"time"

	"github.com/RichardKnop/machinery/v2/backends/result"
	"github.com/RichardKnop/machinery/v2/tasks"
	"github.com/google/uuid"
	"github.com/wechatpay-apiv3/wechatpay-go/core"
	"xiandeng.net.cn/server/constants"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/internal/controller/request_model"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
	"xiandeng.net.cn/server/tasks/server"
)

type StudentService interface {
	GetStudentAccountid(ctx context.Context, accountId uuid.UUID) (uuid.UUID, error)
	UpdateStudySuggestionOnNotExists(ctx context.Context, userAcctId uuid.UUID, userId uuid.UUID, waitResult bool) (string, error)
	UpdateStudentProfile(ctx context.Context, u *models.User, body request_model.BodyUpdateStudentProfile) error
	SearchUniversities(ctx context.Context, Namelike string) ([]string, error)
	IsUniversityGraduateEligible(ctx context.Context, schoolName string) (bool, error)
}

type studentService struct {
	*Service
	tc server.TaskClient
}

func NewStudentService(conf *config.Config, logger *log.Logger, repo db.Repository, tc server.TaskClient) StudentService {
	return &studentService{
		Service: NewService(conf, logger, repo),
		tc:      tc,
	}
}

func (s *studentService) GetStudentAccountid(ctx context.Context, accountId uuid.UUID) (uuid.UUID, error) {
	return s.repo.NewQueries().GetStudentAttr(ctx, accountId)
}

func SendUpdateStudySuggestionTask(ctx context.Context, tc server.TaskClient, accountId uuid.UUID, name string, sex string, major string, university string, mbtitype string) (*result.AsyncResult, error) {
	sig := &tasks.Signature{
		Name: "task_study_suggestion",
		Args: []tasks.Arg{
			{
				Type:  "string",
				Value: accountId.String(),
			},
			{
				Type:  "string",
				Value: name,
			},
			{
				Type:  "string",
				Value: sex,
			},
			{
				Type:  "string",
				Value: major,
			},
			{
				Type:  "string",
				Value: university,
			},
			{
				Type:  "string",
				Value: mbtitype,
			},
		},
	}
	res, err := tc.SendTaskWithContext(ctx, sig)
	if err != nil {

		return nil, err
	}
	return res, err
}

func (s *studentService) UpdateStudySuggestionOnNotExists(ctx context.Context, userAcctId uuid.UUID, userId uuid.UUID, waitResult bool) (string, error) {
	// 获取当前用户的基本信息
	tx, queries, err := s.repo.StartTransaction(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx)

	acct, err := queries.GetAccount(ctx, userAcctId)
	if err != nil {
		return "", err
	}

	data, err := queries.GetStudentAttrsForSuggestGeneration(ctx, models.GetStudentAttrsForSuggestGenerationParams{
		Accountid: userAcctId,
		Userid:    userId,
	})
	if err != nil {
		return "", err
	}

	fmt.Println(userAcctId.String())
	// Set Pending for this student attribute
	err = queries.UpdateStudentStudySuggestion(ctx, models.UpdateStudentStudySuggestionParams{
		Accountid:       userAcctId,
		Studysuggestion: core.String(constants.StudySuggestionGenerationPending),
	})
	tx.Commit(ctx)

	if err != nil {
		return "", err
	}
	res, err := SendUpdateStudySuggestionTask(ctx, s.tc, userAcctId, *acct.Accountname, data.Sex, *data.Major, *data.University, data.Mbtitype.(string))
	if err != nil {
		return "", err
	}
	// 分离async 结果等待
	if !waitResult {
		return "", nil
	}
	latestState := res.GetState()
	count := 0
	for {
		if latestState.IsCompleted() {
			if latestState.IsSuccess() {
				return *latestState.Results[0].Value.(*string), nil
			} else {
				return "", fmt.Errorf("task failed: %v", latestState.Error)
			}
		}
		if count > 10 {
			return "", fmt.Errorf("task timeout")
		}
		count++
		time.Sleep(3 * time.Second)

	}

}

func (s *studentService) UpdateStudentProfile(ctx context.Context, u *models.User, body request_model.BodyUpdateStudentProfile) error {
	tx, qtx, err := s.repo.StartTransaction(ctx)
	if err != nil {
		return fmt.Errorf("start txn failed: %v", err)
	}
	defer tx.Rollback(ctx)

	acctId, err := qtx.GetStudentAccountIdByUserId(ctx, u.ID)
	if err != nil {
		return fmt.Errorf("get student accountid: %v", err)
	}

	// 更新就读建议
	acct, err := qtx.GetAccount(ctx, acctId)
	if err != nil {
		return fmt.Errorf("get account failed: %v", err)
	}
	//如果是专科就不用更新就读建议，直接设置成一个固定字符串即可
	// Set pending status
	//err = qtx.UpdateStudentStudySuggestion(ctx, models.UpdateStudentStudySuggestionParams{
	//	Accountid:       acctId,
	//	Studysuggestion: core.String(constants.StudySuggestionGenerationPending),
	//})
	//if err != nil {
	//	return fmt.Errorf("update studysuggestion failed: %v", err)
	//}
	majorname, err := qtx.GetMajorName(ctx, body.MajorCode)
	if err != nil {
		return fmt.Errorf("get majorname failed: %v", err)
	}

	var entryDate = pgtype.Date{Valid: false}
	if body.EntryDate != nil {
		if *body.EntryDate != "" {
			t, err := time.Parse("2006-01-02", *body.EntryDate)
			if err == nil {
				entryDate = pgtype.Date{
					Time:  t,
					Valid: true,
				}
			}
		}
	}

	// 学年信息
	var degreeYears *int16
	if body.DegreeYears != nil {
		if *body.DegreeYears > 0 {
			degreeYears = body.DegreeYears
		}
	}
	err = qtx.UpdateStudentAttr(ctx, models.UpdateStudentAttrParams{
		UserID:          u.ID,
		University:      &body.University,
		Majorcode:       &body.MajorCode,
		Mbtienergy:      &body.MbtiData.MbtiEnergy,
		Mbtimind:        &body.MbtiData.MbtiMind,
		Mbtidecision:    &body.MbtiData.MbtiDecision,
		Mbtireaction:    &body.MbtiData.MbtiReaction,
		Degree:          models.NullMajortype{Valid: true, Majortype: models.Majortype(body.MajorType)},
		TotalScore:      body.GaokaoData.TotalScore,
		Chinese:         body.GaokaoData.Chinese,
		Mathematics:     body.GaokaoData.Mathematics,
		ForeignLanguage: body.GaokaoData.ForeignLanguage,
		Physics:         body.GaokaoData.Physics,
		Chemistry:       body.GaokaoData.Chemistry,
		Biology:         body.GaokaoData.Biology,
		History:         body.GaokaoData.History,
		Geography:       body.GaokaoData.Geography,
		Politics:        body.GaokaoData.Politics,
		EntryDate:       entryDate,
		DegreeYears:     degreeYears,
	})
	if err != nil {
		return fmt.Errorf("UpdateStudentAttr: %v", err)
	}

	_, err = SendUpdateStudySuggestionTask(
		ctx,
		s.tc,
		acctId,
		*acct.Accountname,
		models.Gender(body.Sex).HumanReadable(),
		*majorname,
		body.University,
		body.MbtiData.Concat(),
	)
	if err != nil {
		return fmt.Errorf("send task failed: %v", err)
	}

	var gender = models.Gender(body.Sex)
	var updateUserParams = models.UpdateUserParams{
		ID:        u.ID,
		Lastname:  &body.LastName,
		Firstname: &body.FirstName,
		Sex:       &gender,
	}
	paramStr, _ := json.Marshal(updateUserParams)
	s.logger.Info("update user params", zap.String("params", string(paramStr)))
	err = qtx.UpdateUser(ctx, updateUserParams)
	if err != nil {
		return fmt.Errorf("UpdateStudentUserProfile: %v", err)
	}
	err = tx.Commit(ctx)
	if err != nil {
		return fmt.Errorf("commit: %x", err)
	}
	return nil
}

func (s *studentService) SearchUniversities(ctx context.Context, Namelike string) ([]string, error) {
	universities, err := s.repo.NewQueries().SearchUniversitiesByNamelike(ctx, "%"+Namelike+"%")
	if err != nil {
		return nil, fmt.Errorf("search universities: %v", err)
	}
	return universities, nil
}

func (s *studentService) IsUniversityGraduateEligible(ctx context.Context, schoolName string) (bool, error) {
	eligible, err := s.repo.NewQueries().IsUniversityGraduateEligible(ctx, schoolName)
	if err != nil {
		return false, fmt.Errorf("check university graduate eligibility: %v", err)
	}
	return *eligible, err
}
