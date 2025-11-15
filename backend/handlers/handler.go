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
		user := api.Group("/user")
		{
			user.GET("/user", h.WMS.GetUser)
			user.POST("/user", h.WMS.CreateUser)
		}
	}

	return r
}
