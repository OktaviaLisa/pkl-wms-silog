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

	var user models.Users
	if err := h.db.Preload("Gudang").Where("username = ?", loginData.Username).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Username atau password salah"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(loginData.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Username atau password salah"})
		return
	}

	namaGudang := ""
	if user.Gudang.NamaGudang != "" {
		namaGudang = user.Gudang.NamaGudang
	}

	user.Password = ""
	c.JSON(http.StatusOK, gin.H{
		"message":     "Login berhasil",
		"user":        user,
		"nama_gudang": namaGudang,
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
		fmt.Println("DB error:", err)
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
	userID := c.Query("user_id")
	fmt.Printf("🔍 GetInboundStock dipanggil dengan user_id: %s\n", userID)

	if userID == "" {
		// Tampilkan semua data jika tidak ada user_id
		var inboundStocks []models.Inbound_Stock
		result := h.db.
			Preload("Produk").
			Preload("GudangAsal").
			Preload("GudangTujuan").
			Find(&inboundStocks)

		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
			return
		}

		var response []map[string]interface{}
		for _, item := range inboundStocks {
			response = append(response, map[string]interface{}{
				"idInbound":          item.IdInbound,
				"idProduk":           item.IdProduk,
				"gudang_asal":        item.GudangAsalId,
				"gudang_tujuan":      item.GudangTujuanId,
				"tanggal_masuk":      item.TanggalMasuk.Format("2006-01-02"),
				"deskripsi":          item.Deskripsi,
				"nama_produk":        item.Produk.NamaProduk,
				"nama_gudang_asal":   item.GudangAsal.NamaGudang,
				"nama_gudang_tujuan": item.GudangTujuan.NamaGudang,
			})
		}

		c.JSON(http.StatusOK, gin.H{"data": response})
		return
	}

	// Cek user ada atau tidak
	var user models.Users
	if err := h.db.Where("idUser = ?", userID).First(&user).Error; err != nil {
		fmt.Printf("❌ User dengan ID %s tidak ditemukan: %v\n", userID, err)

		// Tampilkan daftar user yang ada untuk debugging
		var allUsers []models.Users
		h.db.Find(&allUsers)
		fmt.Printf("📋 Daftar user yang ada:\n")
		for _, u := range allUsers {
			fmt.Printf("   - ID: %d, Username: %s, RoleGudang: %d\n", u.IDUser, u.Username, u.RoleGudang)
		}

		c.JSON(http.StatusNotFound, gin.H{"error": "User tidak ditemukan"})
		return
	}

	// Filter berdasarkan gudang_tujuan = role_gudang user
	var inboundStocks []models.Inbound_Stock
	result := h.db.
		Preload("Produk").
		Preload("GudangAsal").
		Preload("GudangTujuan").
		Where("gudang_tujuan = ?", user.RoleGudang).
		Find(&inboundStocks)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	var response []map[string]interface{}
	for _, item := range inboundStocks {
		response = append(response, map[string]interface{}{
			"idInbound":          item.IdInbound,
			"idProduk":           item.IdProduk,
			"gudang_asal":        item.GudangAsalId,
			"gudang_tujuan":      item.GudangTujuanId,
			"tanggal_masuk":      item.TanggalMasuk.Format("2006-01-02"),
			"deskripsi":          item.Deskripsi,
			"nama_produk":        item.Produk.NamaProduk,
			"nama_gudang_asal":   item.GudangAsal.NamaGudang,
			"nama_gudang_tujuan": item.GudangTujuan.NamaGudang,
		})
	}

	c.JSON(http.StatusOK, gin.H{"data": response})
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

func (h *WMSHandler) GetUserGudang(c *gin.Context) {
	userID := c.Query("user_id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id diperlukan"})
		return
	}

	var user models.Users
	if err := h.db.Preload("Gudang").Where("idUser = ?", userID).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "User gudang retrieved successfully",
		"data": gin.H{
			"nama_gudang": user.Gudang.NamaGudang,
			"id_gudang":   user.RoleGudang,
		},
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

func (h *WMSHandler) CreateGudang(c *gin.Context) {
	var gudang models.Gudang

	// Bind JSON ke struct Gudang
	if err := c.ShouldBindJSON(&gudang); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid input: " + err.Error(),
		})
		return
	}

	// Save ke database
	if err := h.db.Create(&gudang).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Gagal membuat gudang: " + err.Error(),
		})
		return
	}

	// Response sukses
	c.JSON(http.StatusOK, gin.H{
		"message": "Gudang berhasil dibuat",
		"data":    gudang,
	})
}

// OUTBOUND
func (h *WMSHandler) GetOutbound(c *gin.Context) {
	userID := c.Query("user_id")
	fmt.Printf("🔍 GetOutbound dipanggil dengan user_id: %s\n", userID)

	if userID == "" {
		// Tampilkan semua data jika tidak ada user_id
		var outbound []models.Outbound
		result := h.db.
			Preload("Produk").
			Preload("GudangAsalObj").
			Preload("GudangTujuanObj").
			Order("idOutbound DESC").
			Find(&outbound)
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
			return
		}

		var response []map[string]interface{}
		for _, item := range outbound {
			// Format tanggal ke DD-MM-YYYY
			formattedDate := item.TglKeluar.Format("02-01-2006")

			response = append(response, map[string]interface{}{
				"idOutbound":         item.IDOutbound,
				"idProduk":           item.IDProduk,
				"gudang_asal":        item.GudangAsal,
				"gudang_tujuan":      item.GudangTujuan,
				"tgl_keluar":         formattedDate,
				"deskripsi":          item.Deskripsi,
				"nama_produk":        item.Produk.NamaProduk,
				"nama_gudang_asal":   item.GudangAsalObj.NamaGudang,
				"nama_gudang_tujuan": item.GudangTujuanObj.NamaGudang,
			})
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Outbound retrieved successfully",
			"data":    response,
		})
		return
	}

	// Cek user ada atau tidak
	var user models.Users
	if err := h.db.Where("idUser = ?", userID).First(&user).Error; err != nil {
		fmt.Printf("❌ User dengan ID %s tidak ditemukan: %v\n", userID, err)
		c.JSON(http.StatusNotFound, gin.H{"error": "User tidak ditemukan"})
		return
	}

	// Filter berdasarkan gudang_asal = role_gudang user
	var outbound []models.Outbound
	result := h.db.
		Preload("Produk").
		Preload("GudangAsalObj").
		Preload("GudangTujuanObj").
		Where("gudang_asal = ?", user.RoleGudang).
		Order("idOutbound DESC").
		Find(&outbound)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	var response []map[string]interface{}
	for _, item := range outbound {
		// Format tanggal ke DD-MM-YYYY (sama seperti inbound)
		formattedDate := item.TglKeluar.Format("02-01-2006")

		response = append(response, map[string]interface{}{
			"idOutbound":         item.IDOutbound,
			"idProduk":           item.IDProduk,
			"gudang_asal":        item.GudangAsal,
			"gudang_tujuan":      item.GudangTujuan,
			"tgl_keluar":         formattedDate,
			"deskripsi":          item.Deskripsi,
			"nama_produk":        item.Produk.NamaProduk,
			"nama_gudang_asal":   item.GudangAsalObj.NamaGudang,
			"nama_gudang_tujuan": item.GudangTujuanObj.NamaGudang,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Outbound retrieved successfully",
		"data":    response,
	})
}

func (h *WMSHandler) CreateOutbound(c *gin.Context) {
	// request expects idProduk as integer, gudang_asal/tujuan as string
	var input struct {
		IDProduk     int    `json:"idProduk"`
		GudangAsal   string `json:"gudang_asal"`
		GudangTujuan string `json:"gudang_tujuan"`
		TglKeluar    string `json:"tgl_keluar"`
		Deskripsi    string `json:"deskripsi"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		// return error detail to help debugging
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// validate minimal
	if input.IDProduk == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "idProduk harus diisi dan bukan 0"})
		return
	}
	if input.GudangAsal == "" || input.GudangTujuan == "" || input.TglKeluar == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Field gudang_asal, gudang_tujuan, tgl_keluar wajib diisi"})
		return
	}

	// Get or create gudang asal
	idAsal, err := h.GetOrCreateGudang(input.GudangAsal)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat/ambil gudang asal"})
		return
	}

	// Get or create gudang tujuan
	idTujuan, err := h.GetOrCreateGudang(input.GudangTujuan)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat/ambil gudang tujuan"})
		return
	}

	// Parse tanggal ke time.Time
	tanggal, err := time.Parse("2006-01-02", input.TglKeluar)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Format tgl_keluar tidak valid, gunakan YYYY-MM-DD"})
		return
	}

	// Build outbound model
	outbound := models.Outbound{
		IDProduk:     uint(input.IDProduk),
		GudangAsal:   uint(idAsal),
		GudangTujuan: uint(idTujuan),
		TglKeluar:    tanggal,
		Deskripsi:    input.Deskripsi,
	}

	if err := h.db.Create(&outbound).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat outbound: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Outbound created successfully",
		"data":    outbound,
	})
}

func (h *WMSHandler) GetProdukByGudang(c *gin.Context) {
	gudangID := c.Query("gudang_id")
	if gudangID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "gudang_id diperlukan"})
		return
	}

	var produk []models.Produk

	result := h.db.
		Joins("JOIN inbound_stocks ON inbound_stocks.idProduk = produk.idProduk").
		Where("inbound_stocks.gudang_tujuan = ?", gudangID).
		Group("produk.idProduk").
		Find(&produk)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Produk retrieved successfully",
		"data":    produk,
	})
}

func (h *WMSHandler) CreateProduk(c *gin.Context) {
	var produk models.Produk

	// Bind JSON ke struct Gudang
	if err := c.ShouldBindJSON(&produk); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid input: " + err.Error(),
		})
		return
	}

	// Save ke database
	if err := h.db.Create(&produk).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Gagal membuat gudang: " + err.Error(),
		})
		return
	}

	// Response sukses
	c.JSON(http.StatusOK, gin.H{
		"message": "Gudang berhasil dibuat",
		"data":    produk,
	})
}

func (h *WMSHandler) GetSatuan(c *gin.Context) {
	var satuan []models.Satuan
	result := h.db.Find(&satuan)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Satuan retrieved successfully",
		"data":    satuan,
	})
}

func (h *WMSHandler) GetInventory(c *gin.Context) {
	gudangID := c.Query("gudang_id")
	if gudangID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "gudang_id diperlukan"})
		return
	}

	var inventory []models.Inventory
	result := h.db.
		Preload("Produk.Satuan").
		Preload("Gudang").
		Where("idGudang = ?", gudangID).
		Find(&inventory)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	// Format response untuk frontend
	var response []map[string]interface{}
	for _, item := range inventory {
		response = append(response, map[string]interface{}{
			"id_inventory": item.IdInventory,
			"nama_produk":  item.Produk.NamaProduk,
			"kode_produk":  item.Produk.KodeProduk,
			"volume":       item.Produk.Volume,
			"jenis_satuan": item.Produk.Satuan.JenisSatuan,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Inventory retrieved successfully",
		"data":    response,
	})
}
