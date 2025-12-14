package middleware

import (
	"fmt"
	"strings"

	"backend/utils"

	"github.com/gin-gonic/gin"
)

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		fmt.Printf("🔐 Auth Header: %s\n", authHeader)

		if authHeader == "" {
			c.JSON(401, gin.H{"error": "Authorization header kosong"})
			c.Abort()
			return
		}

		tokenString := strings.Replace(authHeader, "Bearer ", "", 1)
		fmt.Printf("🔑 Token: %s\n", tokenString)

		// Gunakan ValidateJWT dari utils
		claims, err := utils.ValidateJWT(tokenString)
		if err != nil {
			fmt.Printf("❌ Token validation error: %v\n", err)
			c.JSON(401, gin.H{"error": "Token tidak valid: " + err.Error()})
			c.Abort()
			return
		}

		fmt.Printf("✅ Token valid - UserID: %d, Role: %d\n", claims.UserID, claims.Role)
		c.Set("user_id", claims.UserID)
		c.Set("role", claims.Role)

		c.Next()
	}
}
