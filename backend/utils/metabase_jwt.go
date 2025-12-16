package utils

import (
	"fmt"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

func GenerateMetabaseChartToken(chartID int, params map[string]interface{}) (string, error) {
	secret := os.Getenv("METABASE_EMBED_SECRET")
	if secret == "" || secret == "YOUR_METABASE_EMBED_SECRET_HERE" {
		return "", fmt.Errorf("METABASE_EMBED_SECRET tidak dikonfigurasi dengan benar")
	}

	fmt.Printf("🔐 Using Metabase secret: %s...\n", secret[:10])
	fmt.Printf("📊 Chart ID: %d\n", chartID)
	fmt.Printf("📋 Params: %+v\n", params)

	claims := jwt.MapClaims{
		"resource": map[string]int{
			"question": chartID,
		},
		"params": params,
		"exp":    time.Now().Add(10 * time.Minute).Unix(),
		"iat":    time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signedToken, err := token.SignedString([]byte(secret))
	if err != nil {
		return "", fmt.Errorf("gagal sign JWT token: %v", err)
	}

	fmt.Printf("✅ Generated JWT: %s...\n", signedToken[:50])
	return signedToken, nil
}
