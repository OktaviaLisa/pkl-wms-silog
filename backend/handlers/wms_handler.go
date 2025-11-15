package handlers

import (
	"fmt"
	"net/http"

	"backend/models"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type WMSHandler struct {
	db *gorm.DB
}

func NewWMSHandler(db *gorm.DB) *WMSHandler {
	return &WMSHandler{db: db}
}

// GET /api/user
func (h *WMSHandler) GetUser(c *gin.Context) {
	var user []models.Users
	result := h.db.Order("username").Find(&user)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Users retrieved successfully",
		"data":    user,
	})
}

func (h *WMSHandler) CreateUser(c *gin.Context) {
	var user models.Users

	// Bind JSON ke struct
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Tampilkan data user yang diterima Flutter
	fmt.Printf("Data diterima: %+v\n", user)

	// Validasi input
	if user.Username == "" || user.Password == "" || user.Email == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username, password, dan email wajib diisi"})
		return
	}

	// Cek username sudah ada
	var existingUser models.Users
	if err := h.db.Where("username = ?", user.Username).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username sudah digunakan"})
		return
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal hash password"})
		return
	}
	user.Password = string(hashedPassword)

	// Log sebelum insert ke DB
	fmt.Printf("Mencoba menyimpan user ke DB: %+v\n", user)

	// Simpan user
	if err := h.db.Create(&user).Error; err != nil {
		fmt.Println("DB error:", err) // <-- ini penting
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat user"})
		return
	}

	// Jangan return password
	user.Password = ""

	c.JSON(http.StatusOK, gin.H{
		"message": "User berhasil dibuat",
		"data":    user,
	})
}
