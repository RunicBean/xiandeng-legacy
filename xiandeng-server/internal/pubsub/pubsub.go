package pubsub

import (
	"fmt"
	"sync"
	"time"
)

type (
	subscribeChannel chan PubMessage
	topicRule        func(msg PubMessage) bool
)

type Publisher struct {
	m             sync.RWMutex
	timeout       time.Duration
	buffer        int
	subscriptions map[subscribeChannel]topicRule
}

type PubMessage struct {
	TopicType string `json:"topic_type"`
	Event     string `json:"event"`
	Data      string `json:"data"`
}

func (p *Publisher) SubscribeTopic(topic topicRule) subscribeChannel {
	ch := make(subscribeChannel, p.buffer)
	p.m.RLock()
	p.subscriptions[ch] = topic
	p.m.RUnlock()
	return ch
}

func (p *Publisher) Evict(sub subscribeChannel) {
	p.m.Lock()
	defer p.m.Unlock()

	delete(p.subscriptions, sub)
	close(sub)
}

func (p *Publisher) Close() {
	p.m.Lock()
	fmt.Print("Closing publisher with it's subscriptions...")
	defer p.m.Unlock()

	for sub := range p.subscriptions {
		delete(p.subscriptions, sub)
		close(sub)
	}
}

func (p *Publisher) Publish(v PubMessage) {
	p.m.Lock()
	defer p.m.Unlock()

	var wg sync.WaitGroup
	for sub, topic := range p.subscriptions {
		wg.Add(1)
		go p.sendTopic(sub, topic, v, &wg)
	}
}

func (p *Publisher) sendTopic(
	sub subscribeChannel, topic topicRule, v PubMessage, wg *sync.WaitGroup,
) {
	defer wg.Done()
	if topic != nil && !topic(v) {
		return
	}

	select {
	case sub <- v:
	case <-time.After(p.timeout):
	}
}

func NewPublisher(publisherTimeout time.Duration, buffer int) *Publisher {
	return &Publisher{
		buffer:        buffer,
		timeout:       publisherTimeout,
		subscriptions: make(map[subscribeChannel]topicRule),
	}
}
