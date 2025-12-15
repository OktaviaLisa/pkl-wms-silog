package utils

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
)

var JwtKey = []byte("rahasia_wms_123")

type JWTClaims struct {
	UserID uint `json:"user_id"`
	Role   int  `json:"role"`
	jwt.RegisteredClaims
}

func GenerateJWT(userID uint, role int) (string, error) {
	var expiry time.Time
	
	if role == 99 { // Admin
		expiry = time.Now().Add(100 * 365 * 24 * time.Hour) // 100 tahun
	} else { // User biasa
		expiry = time.Now().Add(24 * time.Hour) // 24 jam
	}
	
	claims := JWTClaims{
		UserID: userID,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expiry),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(JwtKey)
}

func ValidateJWT(tokenString string) (*JWTClaims, error) {
	token, err := jwt.ParseWithClaims(
		tokenString,
		&JWTClaims{},
		func(token *jwt.Token) (interface{}, error) {
			return JwtKey, nil
		},
	)

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*JWTClaims)
	if !ok || !token.Valid {
		return nil, err
	}

	return claims, nil
}
