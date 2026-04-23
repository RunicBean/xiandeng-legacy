package models

import (
	"context"

	"github.com/google/uuid"
)

const updateAccount = `-- name: UpdateAccount :exec
UPDATE account
SET
  partition = COALESCE($2::accountpartition, partition),
  accountname = COALESCE($3::text, accountname),
  type = COALESCE($4::entitytype, type),
  status = COALESCE($5::accountstatus, status)
WHERE id = $1
`

type UpdateAccountParams struct {
	ID          uuid.UUID         `json:"id"`
	Partition   *Accountpartition `json:"partition"`
	Accountname *string           `json:"accountname"`
	Type        *Entitytype       `json:"type"`
	Status      *Accountstatus    `json:"status"`
	DemoFlag    *bool             `json:"demo_flag"`
	DemoAccount *uuid.UUID        `json:"demo_account"`
}

func (q *Queries) UpdateAccount(ctx context.Context, arg UpdateAccountParams) error {
	_, err := q.db.Exec(
		ctx,
		updateAccount,
		arg.ID,
		arg.Partition,
		arg.Accountname,
		arg.Type,
		arg.Status,
	)
	return err
}

const updateAgentAttribute = `-- name: UpdateAgentAttribute :exec
UPDATE AgentAttribute
SET
  province = COALESCE($2::text, province),
  city = COALESCE($3::text, city),
  agentcode = COALESCE($4::text, agentcode),
  demo_flag = COALESCE($5::bool, demo_flag),
  demo_account = COALESCE($6::uuid, demo_account)
WHERE accountid = $1
`

type UpdateAgentAttributeParams struct {
	Accountid   uuid.UUID  `json:"accountid"`
	Province    *string    `json:"province"`
	City        *string    `json:"city"`
	Agentcode   *string    `json:"agentcode"`
	DemoFlag    *bool      `json:"demo_flag"`
	DemoAccount *uuid.UUID `json:"demo_account"`
}

func (q *Queries) UpdateAgentAttribute(ctx context.Context, arg UpdateAgentAttributeParams) error {
	_, err := q.db.Exec(ctx, updateAgentAttribute,
		arg.Accountid,
		arg.Province,
		arg.City,
		arg.Agentcode,
		arg.DemoFlag,
		arg.DemoAccount,
	)
	return err
}
