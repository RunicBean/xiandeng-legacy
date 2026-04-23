package product

import (
	"bytes"
	"fmt"
	"xiandeng.net.cn/server/pkg/oss"

	"github.com/nguyenthenguyen/docx"
	"xiandeng.net.cn/server/db/models"
)

type ReportGenerator interface {
	GenerateAndUpload(r models.GetStudentPlanningDataRow, oc oss.OSSClient) (string, error)
}

type reportGenerator struct {
	templateReplaceDocx *docx.ReplaceDocx
}

func replaceMap(r models.GetStudentPlanningDataRow) map[string]string {
	return map[string]string{
		"name":                *r.Lastname + *r.Firstname,
		"sex":                 r.Sex.HumanReadable(),
		"university":          *r.University,
		"majorname":           *r.Major,
		"studyingsuggestion":  *r.Studyingsuggestion,
		"majorreference":      *r.Majorreference,
		"charactersuggestion": *r.Charactersuggestion,
	}
}

func (rg *reportGenerator) GenerateAndUpload(r models.GetStudentPlanningDataRow, oc oss.OSSClient) (string, error) {
	e := rg.templateReplaceDocx.Editable()
	for k, targetValue := range replaceMap(r) {
		err := e.Replace(k, targetValue, -1)
		if err != nil {
			return "", fmt.Errorf("replace docx: %v", err)
		}
	}
	localPath := fmt.Sprintf("download/planning-report/%s.docx", r.Userid.String())
	buffer := new(bytes.Buffer)
	// err := e.WriteToFile(localPath)
	err := e.Write(buffer)
	if err != nil {
		return "", fmt.Errorf("write docx file: %v", err)
	}
	// err = oc.PutFile("xiandeng-private", localPath, localPath)
	err = oc.PutBuffer("xiandeng-private", buffer, localPath)
	if err != nil {
		return "", fmt.Errorf("put file: %x", err)
	}
	return localPath, nil
}

var _ ReportGenerator = (*reportGenerator)(nil)

func NewReportGenerator(templatePath string) (ReportGenerator, error) {
	r, err := docx.ReadDocxFile(templatePath)
	if err != nil {
		return nil, fmt.Errorf("planning report generator init: %x", err)
	}
	return &reportGenerator{
		templateReplaceDocx: r,
	}, nil
}
