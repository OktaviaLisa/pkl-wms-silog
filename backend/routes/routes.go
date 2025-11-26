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
	r.GET("/api/gudang/list", h.WMS.GetGudang)
	r.POST("/api/gudang/create", h.WMS.CreateGudang)
	r.GET("/api/gudang/user", h.WMS.GetUserGudang)
	r.GET("/api/outbound/getOutbound", h.WMS.GetOutbound)
	r.POST("/api/outbound/postOutbound", h.WMS.CreateOutbound)

	// tambah routes kamu lainnya di sini
}
