package services

import (
	"context"

	"github.com/google/uuid"
	"xiandeng.net.cn/server/db"
	"xiandeng.net.cn/server/db/models"
	"xiandeng.net.cn/server/pkg/config"
	"xiandeng.net.cn/server/pkg/log"
)

type InventoryService interface {
	CreateInventoryOrder(
		ctx context.Context,
		accountId uuid.UUID,
		productId uuid.UUID,
		quantity int32,
		_type models.Inventoryordertype,
		status models.Inventoryorderstatus,
	) (any, error)
	GetMaximumQuantity(ctx context.Context, accountId uuid.UUID, productId uuid.UUID) (int32, error)
	ListInventory(ctx context.Context, accountId uuid.UUID) ([]models.ListInventoryRow, error)
	ConfirmInventoryOrder(ctx context.Context, ioId string) error
	UpdateInventoryOrderPaymentMethod(ctx context.Context, ioId string, paymentMethod string) error
	InventoryCourseOrders(ctx context.Context, accountId uuid.UUID) ([]models.InventoryCourseOrdersRow, error)
	GetInventoryActivities(ctx context.Context, accountId uuid.UUID) ([]models.GetInventoryActivitiesRow, error)
	ListInventoriesForHQ(ctx context.Context) ([]models.ListInventoriesForHQRow, error)
	UpdateInventoryOrderStatus(ctx context.Context, ioId string, status models.Inventoryorderstatus) error
}

type inventoryService struct {
	*Service
}

var _ InventoryService = (*inventoryService)(nil)

func NewInventoryService(conf *config.Config, logger *log.Logger, repo db.Repository) InventoryService {
	return &inventoryService{
		Service: NewService(conf, logger, repo),
	}
}

func (s *inventoryService) CreateInventoryOrder(
	ctx context.Context,
	accountId uuid.UUID,
	productId uuid.UUID,
	quantity int32,
	_type models.Inventoryordertype,
	status models.Inventoryorderstatus,
) (any, error) {
	ioId, err := s.repo.NewQueries().CreateInventoryOrder(ctx, models.CreateInventoryOrderParams{
		Accountid: accountId,
		Productid: productId,
		Quantity:  quantity,
		Status:    status,
		Type:      _type,
	})
	return ioId, err
}

func (s *inventoryService) GetMaximumQuantity(ctx context.Context, accountId uuid.UUID, productId uuid.UUID) (int32, error) {
	return s.repo.NewQueries().GetMaximumQuantity(ctx, models.GetMaximumQuantityParams{
		Accountid: accountId,
		Productid: productId,
	})
}

func (s *inventoryService) ListInventory(ctx context.Context, accountId uuid.UUID) ([]models.ListInventoryRow, error) {
	return s.repo.NewQueries().ListInventory(ctx, accountId)
}

func (s *inventoryService) ConfirmInventoryOrder(ctx context.Context, ioId string) error {
	return s.repo.NewQueries().ConfirmInventoryOrder(ctx, ioId)
}

func (s *inventoryService) UpdateInventoryOrderPaymentMethod(ctx context.Context, ioId string, paymentMethod string) error {
	return s.repo.NewQueries().UpdateInventoryOrderPaymentMethod(ctx, models.UpdateInventoryOrderPaymentMethodParams{
		Column1:       ioId,
		Paymentmethod: &paymentMethod,
	})
}

func (s *inventoryService) GetInventoryActivities(ctx context.Context, accountId uuid.UUID) ([]models.GetInventoryActivitiesRow, error) {
	return s.repo.NewQueries().GetInventoryActivities(ctx, accountId)
}

func (s *inventoryService) InventoryCourseOrders(ctx context.Context, accountId uuid.UUID) ([]models.InventoryCourseOrdersRow, error) {
	return s.repo.NewQueries().InventoryCourseOrders(ctx, accountId)
}

func (s *inventoryService) ListInventoriesForHQ(ctx context.Context) ([]models.ListInventoriesForHQRow, error) {
	return s.repo.NewQueries().ListInventoriesForHQ(ctx)
}

func (s *inventoryService) UpdateInventoryOrderStatus(ctx context.Context, ioId string, status models.Inventoryorderstatus) error {
	return s.repo.NewQueries().UpdateInventoryOrderStatus(ctx, models.UpdateInventoryOrderStatusParams{
		Column1: ioId,
		Status:  status,
	})
}
