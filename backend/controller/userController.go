package controller

import (
	"backend/config"
	"backend/models"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

func Register(c *gin.Context) {
	var user models.Users

	// Log request yang masuk
	fmt.Println("📝 Request registrasi diterima")
	fmt.Printf("📝 Content-Type: %s\n", c.GetHeader("Content-Type"))
	fmt.Printf("📝 Method: %s\n", c.Request.Method)

	// Log raw body untuk debugging
	body, _ := c.GetRawData()
	fmt.Printf("📝 Raw Body: %s\n", string(body))

	// Reset body untuk ShouldBindJSON
	c.Request.Body = http.NoBody
	c.Request.Body = ioutil.NopCloser(strings.NewReader(string(body)))

	if err := c.ShouldBindJSON(&user); err != nil {
		fmt.Printf("❌ Error parsing JSON: %v\n", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	fmt.Printf("📝 Data diterima - Username: %s, Email: %s\n", user.Username, user.Email)

	// Validasi input
	if user.Username == "" || user.Password == "" || user.Email == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username, password, dan email harus diisi"})
		return
	}

	// Cek apakah username sudah ada
	var existingUser models.Users
	if err := config.DB.Where("username = ?", user.Username).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username sudah digunakan"})
		return
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengenkripsi password"})
		return
	}
	user.Password = string(hashedPassword)

	// Simpan user ke database
	if err := config.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menyimpan data"})
		return
	}

	// Jangan return password yang sudah di-hash
	user.Password = ""

	c.JSON(http.StatusOK, gin.H{
		"message": "Registrasi berhasil!",
		"user":    user,
	})
}
