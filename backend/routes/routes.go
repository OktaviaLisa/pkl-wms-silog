package routes

import (
	"backend/handlers"

	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine, h *handlers.Handler) {

	// contoh endpoint get users
	r.GET("/api/user/user", h.WMS.GetUser)
	r.POST("/api/user/user", h.WMS.CreateUser)

	// tambah routes kamu lainnya di sini
}
