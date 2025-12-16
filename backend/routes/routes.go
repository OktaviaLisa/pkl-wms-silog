package routes

import (
	"backend/handlers"
	"backend/middleware"

	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine, h *handlers.Handler) {

	// =====================
	// 🔓 PUBLIC (NO TOKEN)
	// =====================
	r.POST("/api/auth/login", h.WMS.Login)

	// =====================
	// 🔐 PROTECTED (JWT)
	// =====================
	auth := r.Group("/api")
	auth.Use(middleware.AuthMiddleware())

	// USER
	auth.GET("/user/user", h.WMS.GetUser)
	auth.POST("/user/user", h.WMS.CreateUser)
	auth.PUT("/user/update", h.WMS.UpdateUser)
	auth.DELETE("/user/delete/:idUser", h.WMS.DeleteUser)

	// INBOUND
	auth.GET("/inbound/list", h.WMS.GetInboundStock)
	auth.POST("/inbound/create", h.WMS.CreateInbound)

	// PRODUK
	auth.GET("/produk/list", h.WMS.GetProduk)
	auth.POST("/produk/create", h.WMS.CreateProduk)

	// GUDANG
	auth.GET("/gudang/list", h.WMS.GetGudang)
	auth.POST("/gudang/create", h.WMS.CreateGudang)
	auth.PUT("/gudang/update/:id", h.WMS.UpdateGudang)
	auth.GET("/gudang/user", h.WMS.GetUserGudang)

	// OUTBOUND
	auth.GET("/outbound/getOutbound", h.WMS.GetOutbound)
	auth.POST("/outbound/postOutbound", h.WMS.CreateOutbound)

	// SATUAN
	auth.GET("/satuan/list", h.WMS.GetSatuan)

	// INVENTORY
	auth.GET("/inventory/list", h.WMS.GetInventory)
	auth.GET("/inventory/all", h.WMS.GetAllInventory)
	auth.GET("/inventory/detail/:id", h.WMS.GetInventoryDetail)
	auth.POST("/inventory/add", h.WMS.AddInventory)

	// ORDERS
	auth.PUT("/orders/update-status/:IdOrders", h.WMS.UpdateOrderStatus)

	// QUALITY CONTROL
	auth.POST("/quality-control/add", h.WMS.AddQualityControl)
	auth.GET("/quality-control", h.WMS.GetQualityControl)
	auth.POST("/quality-control/process", h.WMS.ProcessQC)

	// RETURN & CHART
	auth.GET("/return", h.WMS.GetReturn)
	auth.GET("/chart/transactions", h.WMS.GetTransactionChart)
	auth.GET("/chart/transactions/detail", h.WMS.GetTransactionDetail)
	auth.GET("/metabase/inbound-outbound", h.WMS.GetInboundOutboundChart)

}
