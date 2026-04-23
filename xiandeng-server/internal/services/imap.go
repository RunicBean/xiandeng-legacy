package services

import "xiandeng.net.cn/server/pkg/imap"

type ImapService interface {
	Fetch(SubjectStr string, ExcludeSeen bool) error
}

func NewImapService(imapClient imap.ImapClient) ImapService {
	return &imapService{
		imapClient: imapClient,
	}
}

type imapService struct {
	imapClient imap.ImapClient
}

func (s *imapService) Fetch(SubjectStr string, ExcludeSeen bool) error {
	return s.imapClient.Fetch(SubjectStr, ExcludeSeen)
}
