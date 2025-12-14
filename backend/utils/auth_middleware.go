package utils

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// JWTAuthMiddleware → cek token
func JWTAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {

		// Ambil header Authorization
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Authorization header tidak ada",
			})
			c.Abort()
			return
		}

		// Format: Bearer <token>
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Format Authorization harus Bearer <token>",
			})
			c.Abort()
			return
		}

		tokenString := parts[1]

		// Validasi token
		claims, err := ValidateJWT(tokenString)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Token tidak valid atau expired",
			})
			c.Abort()
			return
		}

		// Simpan ke context (biar bisa dipakai handler)
		c.Set("user_id", claims.UserID)
		c.Set("role", claims.Role)

		c.Next()
	}
}
