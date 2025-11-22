package handlers

import (
	"fmt"
	"net/http"
	"time"

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

func (h *WMSHandler) Login(c *gin.Context) {
	var loginData struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}

	if err := c.ShouldBindJSON(&loginData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Data tidak valid"})
		return
	}

	if loginData.Username == "" || loginData.Password == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username dan password harus diisi"})
		return
	}

	// Cari user berdasarkan username
	var user models.Users
	if err := h.db.Where("username = ?", loginData.Username).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Username atau password salah"})
		return
	}

	// Verifikasi password
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(loginData.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Username atau password salah"})
		return
	}

	// Login berhasil
	user.Password = "" // Jangan return password
	c.JSON(http.StatusOK, gin.H{
		"message": "Login berhasil",
		"user":    user,
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

func (h *WMSHandler) GetInboundStock(c *gin.Context) {
	fmt.Println("📋 GET /api/inbound/list dipanggil")

	var inboundStocks []models.Inbound_Stock

	result := h.db.
		Preload("Produk").
		Preload("GudangAsal").
		Preload("GudangTujuan").
		Find(&inboundStocks)

	if result.Error != nil {
		fmt.Printf("❌ Database error: %v\n", result.Error)
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	fmt.Printf("✅ Ditemukan %d data inbound\n", len(inboundStocks))

	// Transform data untuk frontend
	var response []map[string]interface{}
	for _, item := range inboundStocks {
		response = append(response, map[string]interface{}{
			"idInbound":     item.IdInbound,
			"idProduk":      item.IdProduk,
			"tanggal_masuk": item.TanggalMasuk.Format("2006-01-02"),
			"deskripsi":     item.Deskripsi,
			"produk": map[string]interface{}{
				"nama_produk": item.Produk.NamaProduk,
			},
			"gudang_asal": map[string]interface{}{
				"nama_gudang": item.GudangAsal.NamaGudang,
			},
			"gudang_tujuan": map[string]interface{}{
				"nama_gudang": item.GudangTujuan.NamaGudang,
			},
		})
	}

	fmt.Printf("📤 Mengirim response dengan %d items\n", len(response))
	c.JSON(http.StatusOK, gin.H{
		"message": "Inbound stock retrieved successfully",
		"data":    response,
	})
}

func (h *WMSHandler) GetProduk(c *gin.Context) {
	var produk []models.Produk

	result := h.db.Find(&produk)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Produk retrieved successfully",
		"data":    produk,
	})
}

func (h *WMSHandler) GetGudang(c *gin.Context) {
	var gudang []models.Gudang

	result := h.db.Find(&gudang)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Gudang retrieved successfully",
		"data":    gudang,
	})
}

func (h *WMSHandler) GetOrCreateProduk(nama string) (int, error) {
	var p models.Produk

	err := h.db.Where("nama_produk = ?", nama).First(&p).Error
	if err == nil {
		return p.IdProduk, nil
	}

	newP := models.Produk{
		KodeProduk: "AUTO-" + nama,
		NamaProduk: nama,
		Volume:     1,
		IdSatuan:   1,
	}

	if err := h.db.Create(&newP).Error; err != nil {
		return 0, err
	}

	return newP.IdProduk, nil
}

func (h *WMSHandler) GetOrCreateGudang(nama string) (int, error) {
	var g models.Gudang

	err := h.db.Where("nama_gudang = ?", nama).First(&g).Error
	if err == nil {
		return g.IdGudang, nil
	}

	newG := models.Gudang{
		NamaGudang: nama,
		Alamat:     "-",
	}

	if err := h.db.Create(&newG).Error; err != nil {
		return 0, err
	}

	return newG.IdGudang, nil
}

func (h *WMSHandler) CreateInbound(c *gin.Context) {
	var input struct {
		NamaProduk   string `json:"nama_produk"`
		GudangAsal   string `json:"gudang_asal"`
		GudangTujuan string `json:"gudang_tujuan"`
		TanggalMasuk string `json:"tanggal_masuk"`
		Deskripsi    string `json:"deskripsi"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 1. Cari atau buat produk
	idProduk, err := h.GetOrCreateProduk(input.NamaProduk)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat produk"})
		return
	}

	// 2. Cari atau buat gudang asal
	idGudangAsal, err := h.GetOrCreateGudang(input.GudangAsal)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat gudang asal"})
		return
	}

	// 3. Cari atau buat gudang tujuan
	idGudangTujuan, err := h.GetOrCreateGudang(input.GudangTujuan)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat gudang tujuan"})
		return
	}

	// 4. Parse tanggal
	tanggal, err := time.Parse("2006-01-02", input.TanggalMasuk)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Format tanggal tidak valid, gunakan YYYY-MM-DD"})
		return
	}

	// 5. Buat inbound stock
	inbound := models.Inbound_Stock{
		IdProduk:       idProduk,
		GudangAsalId:   idGudangAsal,
		GudangTujuanId: idGudangTujuan,
		TanggalMasuk:   tanggal,
		Deskripsi:      input.Deskripsi,
	}

	if err := h.db.Create(&inbound).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat inbound"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Inbound berhasil dibuat dengan data baru",
		"data":    inbound,
	})
}
