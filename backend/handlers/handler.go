package handlers

import (
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type Handler struct {
	WMS *WMSHandler
}

func NewHandler(DB *gorm.DB) *Handler {
	return &Handler{
		WMS: NewWMSHandler(DB),
	}
}

func SetupRoutes(h *Handler) *gin.Engine {
	r := gin.Default()
	r.Use(cors.Default())

	api := r.Group("/api")
	{
		login := api.Group("/auth")
		{
			login.POST("/login", h.WMS.Login)
		}
		user := api.Group("/user")
		{
			user.GET("/user", h.WMS.GetUser)
			user.POST("/user", h.WMS.CreateUser)
		}
		inbound := api.Group("/inbound")
		{
			inbound.GET("/list", h.WMS.GetInboundStock)
			inbound.POST("/create", h.WMS.CreateInbound)
		}
		produk := api.Group("/produk")
		{
			produk.GET("/list", h.WMS.GetProduk)
			produk.GET("/create", h.WMS.CreateProduk)
		}
		gudang := api.Group("/gudang")
		{
			gudang.GET("/list", h.WMS.GetGudang)
			gudang.GET("/user", h.WMS.GetUserGudang)
			gudang.POST("/create", h.WMS.CreateGudang)
		}
		outbound := api.Group("/outbound")
		{
			outbound.GET("/getOutbound", h.WMS.GetOutbound)
			outbound.POST("/postOutbound", h.WMS.CreateOutbound)
		}
		satuan := api.Group("/satuan")
		{
			satuan.GET("/list", h.WMS.GetSatuan)
		}
	}

	return r
}
