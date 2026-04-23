package tests

import (
	"fmt"
	"io"
	"testing"

	. "gopkg.in/check.v1"
)

func Test(t *testing.T) {
	TestingT(t)
}

type MySuite struct{}

var _ = Suite(&MySuite{})

func (s *MySuite) TestHelloWorld(c *C) {
	// c.Assert(42, Equals, "42")
	fmt.Println("hello")
	c.Assert(io.ErrClosedPipe, ErrorMatches, "io: .*on closed pipe")
	c.Check(42, Equals, 42)
}

//func (s *MySuite) TestScraper(c *C) {
//	scp := scraper.Scraper{}
//	scp.SetTargetUrl(constants.RECRUIT_URL, http.MethodPost)
//}
