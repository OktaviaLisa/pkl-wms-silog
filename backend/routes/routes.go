package routes

import (
	"backend/handlers"

	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine, h *handlers.Handler) {

	// contoh endpoint get users
	r.GET("/api/user/user", h.WMS.GetUser)
	r.POST("/api/user/user", h.WMS.CreateUser)
	r.POST("/api/auth/login", h.WMS.Login)
	r.GET("/api/inbound/list", h.WMS.GetInboundStock)
	r.POST("/api/inbound/create", h.WMS.CreateInbound)
	r.GET("/api/produk/list", h.WMS.GetProduk)
	r.POST("/api/produk/create", h.WMS.CreateProduk)
	r.GET("/api/gudang/list", h.WMS.GetGudang)
	r.POST("/api/gudang/create", h.WMS.CreateGudang)
	r.GET("/api/gudang/user", h.WMS.GetUserGudang)
	r.GET("/api/outbound/getOutbound", h.WMS.GetOutbound)
	r.POST("/api/outbound/postOutbound", h.WMS.CreateOutbound)
	r.GET("/api/satuan/list", h.WMS.GetSatuan)
	r.GET("/api/inventory/list", h.WMS.GetInventory)
	r.POST("/api/inventory/add", h.WMS.AddInventory)
	r.PUT("/api/orders/update-status/:IdOrders", h.WMS.UpdateOrderStatus)
	r.GET("/api/inventory/all", h.WMS.GetAllInventory)
	r.GET("/api/inventory/detail/:id", h.WMS.GetInventoryDetail)
	r.PUT("/api/user/update", h.WMS.UpdateUser)
	r.DELETE("/api/user/delete/:idUser", h.WMS.DeleteUser)
	r.POST("/api/quality-control/add", h.WMS.AddQualityControl)
	r.GET("/api/quality-control", h.WMS.GetQualityControl)
	r.POST("/api/quality-control/process", h.WMS.ProcessQC)
	r.GET("/api/return", h.WMS.GetReturn)
}
