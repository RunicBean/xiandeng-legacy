package constants

type GinContextKey struct{}
type InternalResource struct{}

type ContextKey string

const (
	ContextKeyGin      ContextKey = "gin"
	ContextKeyDb       ContextKey = "db"
	ContextKeyResource ContextKey = "resource"
)

const (
	StudySuggestionGenerationPending = "pending"
)

type WordingNamespace string

var WordingNamespaceItems = map[WordingNamespace]string{
	WordingNamespaceEntitytype:           "entitytype",
	WordingNamespacePaymentMethod:        "paymentmethod",
	WordingNamespaceAcctBalanceType:      "accountbalancetype",
	WordingNamespaceAcctPartition:        "accountpartition",
	WordingNamespaceAcctStatus:           "accountstatus",
	WordingNamespaceInventoryOrderStatus: "inventoryorderstatus",
	WordingNamespaceInventoryOrderType:   "inventoryordertype",
	WordingNamespaceWithdrawType:         "withdrawtype",
	WordingNamespaceWithdrawStatus:       "withdrawstatus",
	WordingNamespaceOrderStatus:          "orderstatus",
}

const (
	WordingNamespaceEntitytype           WordingNamespace = "entitytype"
	WordingNamespacePaymentMethod        WordingNamespace = "paymentmethod"
	WordingNamespaceAcctBalanceType      WordingNamespace = "accountbalancetype"
	WordingNamespaceAcctPartition        WordingNamespace = "accountpartition"
	WordingNamespaceAcctStatus           WordingNamespace = "accountstatus"
	WordingNamespaceInventoryOrderStatus WordingNamespace = "inventoryorderstatus"
	WordingNamespaceInventoryOrderType   WordingNamespace = "inventoryordertype"
	WordingNamespaceWithdrawType         WordingNamespace = "withdrawtype"
	WordingNamespaceWithdrawStatus       WordingNamespace = "withdrawstatus"
	WordingNamespaceOrderStatus          WordingNamespace = "orderstatus"
)

func (n WordingNamespace) IsValid() bool {
	_, ok := WordingNamespaceItems[n]
	return ok
}

type RequireRole string

const (
	RequireRoleAgent   RequireRole = "agent"
	RequireRoleStudent RequireRole = "student"
)
