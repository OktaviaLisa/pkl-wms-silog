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

	// tambah routes kamu lainnya di sini
}
