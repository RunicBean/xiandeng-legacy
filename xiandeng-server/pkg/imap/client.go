package imap

import (
	"fmt"
	"io"
	"log"
	"os"
	"strings"

	"github.com/emersion/go-imap"
	imapid "github.com/emersion/go-imap-id"
	"github.com/emersion/go-imap/client"
	"github.com/emersion/go-message/charset"
	"github.com/emersion/go-message/mail"
	"xiandeng.net.cn/server/pkg/config"
)

type ImapClient interface {
	Connect() error
	// Login(username string, password string) error
	Fetch(SubjectStr string, ExcludeSeen bool) error
}

type imapClient struct {
	conf   *config.Config
	client *client.Client
}

var _ ImapClient = (*imapClient)(nil)

func NewImapClient(conf *config.Config) ImapClient {
	ic := &imapClient{conf: conf}
	ic.Connect()
	return ic
}

func init() {
	imap.CharsetReader = charset.Reader
}

func (c *imapClient) Connect() error {

	if c.client != nil && c.client.State() == imap.AuthenticatedState {
		return nil
	} else {
		client, err := client.DialTLS(fmt.Sprintf("%s:%d", c.conf.IMAP.Host, c.conf.IMAP.Port), nil)
		if err != nil {
			return fmt.Errorf("imapclient.DialTLS: %v", err)
		}
		c.client = client
		if err := c.client.Login(c.conf.IMAP.Username, c.conf.IMAP.Password); err != nil {
			return fmt.Errorf("failed to login: %v", err)
		}
		return nil
	}
}

func (c *imapClient) Fetch(SubjectStr string, ExcludeSeen bool) error {
	c.Connect()
	idClient := imapid.NewClient(c.client)
	idClient.ID(
		imapid.ID{
			imapid.FieldName:    "IMAPClient",
			imapid.FieldVersion: "3.1.0",
		},
	)
	_, err := c.client.Select("INBOX", true)
	if err != nil {
		log.Fatal(err)
	}
	criteria := imap.SearchCriteria{}
	if ExcludeSeen {
		criteria.WithoutFlags = []string{imap.SeenFlag}
	}
	if SubjectStr != "" {
		criteria.Header = map[string][]string{
			// "Subject": {fmt.Sprintf("*%s*", SubjectStr)},
			// "From": {"liuliubank@126.com"},
		}
		// criteria.Header = []imap.SearchCriteriaHeaderField{
		// 	{Key: "Subject", Value: SubjectStr},
		// }
		// criteria.Text = []string{
		// 	SubjectStr,
		// }
	}
	// options := imap.SearchOptions{
	// 	ReturnCount: true,
	// }
	ids, err := c.client.Search(&criteria)
	if err != nil {
		return err
	}

	seqset := new(imap.SeqSet)
	seqset.AddNum(ids...)

	sect := &imap.BodySectionName{}
	messages := make(chan *imap.Message, 100)
	done := make(chan error, 1)
	go func() {
		done <- c.client.Fetch(seqset, []imap.FetchItem{sect.FetchItem(), imap.FetchEnvelope}, messages)
	}()
	filteredCount := 0
	for msg := range messages {
		// 标题包含的字符筛选放在这里
		if !strings.Contains(msg.Envelope.Subject, SubjectStr) {
			continue
		}
		filteredCount += 1
		item := msg.GetBody(sect)
		if item == nil {
			break
		}
		mr, err := mail.CreateReader(item)
		if err != nil {
			log.Fatalf("failed to create mail reader: %v", err)
		}
		parseEmail(mr)

	}
	fmt.Println("fetching emails", "count", filteredCount)
	return nil
}

func parseEmail(mr *mail.Reader) {
	header := mr.Header
	sub, _ := header.Subject()
	fmt.Println(sub)
	for {
		p, err := mr.NextPart()
		if err == io.EOF {
			break
		} else if err != nil {
			log.Fatalf("failed to read message part: %v", err)
		}

		switch h := p.Header.(type) {
		case *mail.InlineHeader:
			// This is the message's text (can be plain-text or HTML)
			// io.ReadAll(p.Body)

			// log.Printf("Inline text: %v", string(b))
		case *mail.AttachmentHeader:
			// This is an attachment
			filename, _ := h.Filename()
			b, _ := io.ReadAll(p.Body)
			// log.Printf("Attachment: %v", filename)
			os.WriteFile(filename, b, 0644)
		}
	}

}
