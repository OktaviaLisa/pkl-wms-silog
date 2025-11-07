package main

import (
	"backend/config"

	"github.com/gin-gonic/gin"
)

func main() {
	// 1. Konek database
	config.ConnectDatabase()

	// 2. Siapkan router
	r := gin.Default()

	// 3. Contoh endpoint sederhana
	r.GET("/ping", func(c *gin.Context) {
		c.JSON(200, gin.H{"message": "pong"})
	})

	// 4. Jalankan server
	r.Run(":8080")
}
