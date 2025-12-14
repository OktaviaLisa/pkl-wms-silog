package handlers

import (
	"errors"
	"fmt"
	"net/http"
	"time"

	"backend/models"
	"backend/utils"

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

// USER
func (h *WMSHandler) GetUser(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

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

	if loginData.Username == "admin" && loginData.Password == "admin123" {
		// Bisa pakai IDUser = 0 atau 1, role = misal 99 untuk admin
		token, err := utils.GenerateJWT(0, 99)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal generate token"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message":     "Login admin berhasil",
			"token":       token,
			"user":        gin.H{"IDUser": 0, "Username": "admin", "RoleGudang": 99},
			"nama_gudang": "",
		})
		return
	}

	var user models.Users
	if err := h.db.Preload("Gudang").
		Where("username = ?", loginData.Username).
		First(&user).Error; err != nil {

		c.JSON(http.StatusUnauthorized, gin.H{"error": "Username atau password salah"})
		return
	}

	if err := bcrypt.CompareHashAndPassword(
		[]byte(user.Password),
		[]byte(loginData.Password),
	); err != nil {

		c.JSON(http.StatusUnauthorized, gin.H{"error": "Username atau password salah"})
		return
	}

	// =========================
	// 🔐 TAMBAHAN: GENERATE JWT
	// =========================
	token, err := utils.GenerateJWT(user.IDUser, user.RoleGudang)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal generate token"})
		return
	}

	fmt.Println("JWT TOKEN:", token)

	namaGudang := ""
	if user.Gudang.NamaGudang != "" {
		namaGudang = user.Gudang.NamaGudang
	}

	user.Password = ""

	// =========================
	// ✨ RESPONSE BARU
	// =========================
	c.JSON(http.StatusOK, gin.H{
		"message":     "Login berhasil",
		"token":       token, // ⬅️ INI TOKEN
		"user":        user,
		"nama_gudang": namaGudang,
	})
}

func (h *WMSHandler) CreateUser(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

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

func (w *WMSHandler) UpdateUser(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	var req struct {
		IdUser     int `json:"idUser"`
		RoleGudang int `json:"role_gudang"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// GORM EXEC → result hanya 1 value
	res := w.db.Exec("UPDATE users SET role_gudang = ? WHERE idUser = ?", req.RoleGudang, req.IdUser)

	if res.Error != nil {
		c.JSON(500, gin.H{"error": res.Error.Error()})
		return
	}

	if res.RowsAffected == 0 {
		c.JSON(404, gin.H{"error": "User tidak ditemukan"})
		return
	}

	c.JSON(200, gin.H{"message": "User updated"})
}

func (w *WMSHandler) DeleteUser(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	idUser := c.Param("idUser")

	// GORM EXEC
	res := w.db.Exec("DELETE FROM users WHERE idUser = ?", idUser)

	if res.Error != nil {
		c.JSON(500, gin.H{"error": res.Error.Error()})
		return
	}

	if res.RowsAffected == 0 {
		c.JSON(404, gin.H{"error": "User tidak ditemukan"})
		return
	}

	c.JSON(200, gin.H{"message": "User deleted"})
}

func (h *WMSHandler) GetInboundStock(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID JWT:", userID)
	fmt.Println("Role JWT:", role)

	// 🔐 VALIDASI JWT
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	// Ambil user
	var user models.Users
	if err := h.db.Where("idUser = ?", userID).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User tidak ditemukan"})
		return
	}

	// Filter inbound sesuai gudang user
	var inboundStocks []models.Orders
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
			"idOrders":           item.IdOrders,
			"kode_produk":        item.Produk.KodeProduk,
			"nama_produk":        item.Produk.NamaProduk,
			"volume":             item.Volume,
			"status":             item.Status,
			"tanggal_masuk":      item.TanggalMasuk.Format("2006-01-02"),
			"deskripsi":          item.Deskripsi,
			"nama_gudang_asal":   item.GudangAsal.NamaGudang,
			"nama_gudang_tujuan": item.GudangTujuan.NamaGudang,
		})
	}

	c.JSON(http.StatusOK, gin.H{"data": response})
}

func (h *WMSHandler) GetProduk(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	type ProdukWithSatuan struct {
		IdProduk    int    `json:"id_produk"`
		KodeProduk  string `json:"kode_produk"`
		NamaProduk  string `json:"nama_produk"`
		IdSatuan    int    `json:"id_satuan"`
		JenisSatuan string `json:"jenis_satuan"`
	}

	var produkList []ProdukWithSatuan

	// JOIN manual untuk memastikan data satuan ter-load
	result := h.db.Table("produk").
		Select("produk.idProduk as id_produk, produk.kode_produk, produk.nama_produk, produk.idSatuan as id_satuan, COALESCE(satuan.jenis_satuan, 'Belum ada satuan') as jenis_satuan").
		Joins("LEFT JOIN satuan ON satuan.idSatuan = produk.idSatuan").
		Scan(&produkList)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Produk retrieved successfully",
		"data":    produkList,
	})
}

func (h *WMSHandler) GetGudang(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

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

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	// JWT pasti ada → userID tidak mungkin 0
	var user models.Users
	if err := h.db.
		Preload("Gudang").
		Where("idUser = ?", userID).
		First(&user).Error; err != nil {

		c.JSON(http.StatusNotFound, gin.H{"error": "User tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "User gudang retrieved successfully",
		"data": gin.H{
			"nama_gudang": user.Gudang.NamaGudang,
			"idGudang":    user.RoleGudang,
		},
	})
}

func (h *WMSHandler) GetOrCreateProduk(kodeProduk, nama string) (int, error) {

	var p models.Produk

	err := h.db.Where("nama_produk = ?", nama).First(&p).Error
	if err == nil {
		return p.IdProduk, nil
	}

	newP := models.Produk{
		KodeProduk: kodeProduk,
		NamaProduk: nama,
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

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	var input struct {
		NamaProduk   string `json:"nama_produk"`
		KodeProduk   string `json:"kode_produk"`
		GudangAsal   string `json:"gudang_asal"`
		GudangTujuan string `json:"gudang_tujuan"`
		Volume       int    `json:"volume"`
		TanggalMasuk string `json:"tanggal_masuk"`
		Deskripsi    string `json:"deskripsi"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	fmt.Printf("=== INPUT RECEIVED ===\n")
	fmt.Printf("Kode Produk: %s\n", input.KodeProduk)
	fmt.Printf("Nama Produk: %s\n", input.NamaProduk)
	fmt.Printf("======================\n")

	// 1. Cari atau buat produk dengan kode yang benar
	idProduk, err := h.GetOrCreateProduk(input.KodeProduk, input.NamaProduk)
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
	inbound := models.Orders{
		IdProduk:       idProduk,
		GudangAsalId:   idGudangAsal,
		GudangTujuanId: idGudangTujuan,
		Volume:         input.Volume,
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

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

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

func (h *WMSHandler) UpdateGudang(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	id := c.Param("id")
	var gudang models.Gudang

	if err := c.ShouldBindJSON(&gudang); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// UPDATE sesuai nama kolom di database
	if err := h.db.Model(&models.Gudang{}).
		Where("idGudang = ?", id).
		Updates(map[string]interface{}{
			"nama_gudang": gudang.NamaGudang,
			"alamat":      gudang.Alamat,
		}).Error; err != nil {

		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Gudang updated"})
}

// OUTBOUND
func (h *WMSHandler) GetOutbound(c *gin.Context) {

	userID := c.GetUint("user_id")
	roleGudang := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", roleGudang)

	var outboundStocks []models.Orders

	query := h.db.
		Preload("Produk").
		Preload("GudangAsal").
		Preload("GudangTujuan").
		Order("idOrders DESC")

	// roleGudang = 0 → admin (lihat semua)
	if roleGudang != 0 {
		query = query.Where("gudang_asal = ?", roleGudang)
	}

	if err := query.Find(&outboundStocks).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var response []map[string]interface{}
	for _, item := range outboundStocks {
		response = append(response, map[string]interface{}{
			"idOrders":           item.IdOrders,
			"idProduk":           item.IdProduk,
			"gudang_asal":        item.GudangAsalId,
			"gudang_tujuan":      item.GudangTujuanId,
			"tanggal_keluar":     item.TanggalMasuk.Format("02-01-2006"),
			"deskripsi":          item.Deskripsi,
			"nama_produk":        item.Produk.NamaProduk,
			"nama_gudang_asal":   item.GudangAsal.NamaGudang,
			"nama_gudang_tujuan": item.GudangTujuan.NamaGudang,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Outbound retrieved successfully",
		"data":    response,
	})
}

func (h *WMSHandler) CreateOutbound(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	var input struct {
		IdProduk     int    `json:"idProduk"`
		GudangAsal   string `json:"gudang_asal"`
		GudangTujuan string `json:"gudang_tujuan"`
		TglKeluar    string `json:"tgl_keluar"`
		Deskripsi    string `json:"deskripsi"`
		Volume       int    `json:"volume"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if input.IdProduk == 0 || input.GudangAsal == "" || input.GudangTujuan == "" || input.TglKeluar == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Semua field wajib diisi"})
		return
	}

	if input.Volume <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Volume harus lebih dari 0"})
		return
	}

	idAsal, err := h.GetOrCreateGudang(input.GudangAsal)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal ambil gudang asal"})
		return
	}

	idTujuan, err := h.GetOrCreateGudang(input.GudangTujuan)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal ambil gudang tujuan"})
		return
	}

	tanggal, err := time.Parse("2006-01-02", input.TglKeluar)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Format tanggal salah (YYYY-MM-DD)"})
		return
	}

	// Mulai database transaction
	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 1. Cek dan ambil data inventory di gudang asal
	var inventory models.Inventory
	if err := tx.Where("idProduk = ? AND idGudang = ?", input.IdProduk, idAsal).First(&inventory).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusNotFound, gin.H{"error": "Stok produk tidak ditemukan di gudang asal"})
		return
	}

	// 2. Validasi volume (double check dari backend)
	if input.Volume > inventory.Volume {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Volume outbound (%d) melebihi stok tersedia (%d)", input.Volume, inventory.Volume),
		})
		return
	}

	// 3. Update inventory - kurangi volume
	inventory.Volume -= input.Volume
	if err := tx.Save(&inventory).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal update inventory: " + err.Error()})
		return
	}

	// 4. Ambil data produk untuk mendapatkan satuan
	var produk models.Produk
	if err := tx.Preload("Satuan").Where("idProduk = ?", input.IdProduk).First(&produk).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusNotFound, gin.H{"error": "Produk tidak ditemukan"})
		return
	}

	// 5. Buat record outbound
	outbound := models.Orders{
		IdProduk:       input.IdProduk,
		GudangAsalId:   idAsal,
		GudangTujuanId: idTujuan,
		TanggalMasuk:   tanggal,
		Volume:         input.Volume,
		Deskripsi:      input.Deskripsi,
		Status:         "outbound",
	}

	if err := tx.Create(&outbound).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal simpan outbound: " + err.Error()})
		return
	}

	// 6. Commit transaction
	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal commit transaction: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":      "Outbound created successfully",
		"data":         outbound,
		"jenis_satuan": produk.Satuan.JenisSatuan,
		"sisa_stok":    inventory.Volume,
	})
}

func (h *WMSHandler) GetProdukByGudang(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	gudangID := c.Query("gudang_id")
	if gudangID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "gudang_id diperlukan"})
		return
	}

	var produk []models.Produk

	result := h.db.
		Joins("JOIN Orders ON Orders.idProduk = produk.idProduk").
		Where("Orders.gudang_tujuan = ?", gudangID).
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

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	var produk models.Produk

	// Bind JSON ke struct Produk
	if err := c.ShouldBindJSON(&produk); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid input: " + err.Error(),
		})
		return
	}

	fmt.Printf("=== CREATE PRODUK ===\n")
	fmt.Printf("Input Kode: %s\n", produk.KodeProduk)
	fmt.Printf("Input Nama: %s\n", produk.NamaProduk)

	// Set default satuan jika belum ada
	if produk.IdSatuan == 0 {
		produk.IdSatuan = 1
	}

	// Save ke database
	if err := h.db.Create(&produk).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Gagal membuat produk: " + err.Error(),
		})
		return
	}

	fmt.Printf("Produk berhasil dibuat dengan ID: %d\n", produk.IdProduk)
	fmt.Printf("Kode tersimpan: %s\n", produk.KodeProduk)
	fmt.Printf("=====================\n")

	// Response sukses
	c.JSON(http.StatusOK, gin.H{
		"message": "Produk berhasil dibuat",
		"data":    produk,
	})
}

func (h *WMSHandler) GetSatuan(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

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

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

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

	var response []map[string]interface{}
	for _, item := range inventory {
		response = append(response, map[string]interface{}{
			"id_inventory": item.IdInventory,
			"idProduk":     item.IdProduk,
			"nama_produk":  item.Produk.NamaProduk,
			"kode_produk":  item.Produk.KodeProduk,
			"volume":       item.Volume,
			"jenis_satuan": item.Produk.Satuan.JenisSatuan,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Inventory retrieved successfully",
		"data":    response,
	})
}

func (h *WMSHandler) AddInventory(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	var input struct {
		IdProduk int `json:"idProduk"`
		IdGudang int `json:"idGudang"`
		Volume   int `json:"volume"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var inventory models.Inventory
	err := h.db.Where("idProduk = ? AND idGudang = ?", input.IdProduk, input.IdGudang).
		First(&inventory).Error

	// Jika belum ada → buat baru
	if errors.Is(err, gorm.ErrRecordNotFound) {
		newStock := models.Inventory{
			IdProduk: input.IdProduk,
			IdGudang: input.IdGudang,
			Volume:   input.Volume,
		}
		h.db.Create(&newStock)
		c.JSON(http.StatusOK, gin.H{"message": "Inventory baru dibuat", "data": newStock})
		return
	}

	// Jika sudah ada → update stok (add)
	inventory.Volume += input.Volume
	h.db.Save(&inventory)

	c.JSON(http.StatusOK, gin.H{
		"message": "Stok berhasil ditambahkan",
		"data":    inventory,
	})
}

func (h *WMSHandler) GetInventoryDetail(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	inventoryID := c.Param("id")
	if inventoryID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "inventory_id diperlukan"})
		return
	}

	var inventory models.Inventory
	result := h.db.
		Preload("Produk.Satuan").
		Preload("Gudang").
		Where("idInventory = ?", inventoryID).
		First(&inventory)

	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Inventory tidak ditemukan"})
		return
	}

	// Debug: cek data gudang
	fmt.Printf("🏢 Gudang data: ID=%d, Nama=%s, Alamat=%s\n",
		inventory.Gudang.IdGudang, inventory.Gudang.NamaGudang, inventory.Gudang.Alamat)

	// Ambil riwayat transaksi untuk produk ini di gudang ini
	var orders []models.Orders
	h.db.
		Preload("GudangAsal").
		Preload("GudangTujuan").
		Where("idProduk = ? AND (gudang_asal = ? OR gudang_tujuan = ?)",
			inventory.IdProduk, inventory.IdGudang, inventory.IdGudang).
		Order("tgl DESC").
		Limit(10).
		Find(&orders)

	// Format riwayat transaksi
	var riwayat []map[string]interface{}
	for _, order := range orders {
		tipeTransaksi := "inbound"
		if order.GudangAsalId == inventory.IdGudang {
			tipeTransaksi = "outbound"
		}

		riwayat = append(riwayat, map[string]interface{}{
			"tipe":          tipeTransaksi,
			"volume":        order.Volume,
			"tanggal":       order.TanggalMasuk.Format("02-01-2006"),
			"deskripsi":     order.Deskripsi,
			"gudang_asal":   order.GudangAsal.NamaGudang,
			"gudang_tujuan": order.GudangTujuan.NamaGudang,
		})
	}

	response := map[string]interface{}{
		"id_inventory": inventory.IdInventory,
		"idProduk":     inventory.IdProduk,
		"nama_produk":  inventory.Produk.NamaProduk,
		"kode_produk":  inventory.Produk.KodeProduk,
		"volume":       inventory.Volume,
		"jenis_satuan": inventory.Produk.Satuan.JenisSatuan,
		"nama_gudang":  inventory.Gudang.NamaGudang,
		"alamat":       inventory.Gudang.Alamat,
		"riwayat":      riwayat,
	}

	// Debug: cek response yang dikirim
	fmt.Printf("📦 Response detail: %+v\n", response)

	c.JSON(http.StatusOK, gin.H{
		"message": "Inventory detail retrieved successfully",
		"data":    response,
	})
}

func (h *WMSHandler) UpdateOrderStatus(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	IdOrders := c.Param("IdOrders") // FIX: hapus spasi

	var input struct {
		Status string `json:"status"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(400, gin.H{"error": "Invalid input"})
		return
	}

	result := h.db.Model(&models.Orders{}).
		Where("IdOrders = ?", IdOrders).
		Update("status", input.Status)

	if result.Error != nil {
		c.JSON(500, gin.H{"error": result.Error.Error()})
		return
	}

	if result.RowsAffected == 0 {
		c.JSON(404, gin.H{"error": "Order not found"})
		return
	}

	c.JSON(200, gin.H{"message": "Status updated"})
}

// GET ALL INVENTORY (admin inventory)
func (h *WMSHandler) GetAllInventory(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	var inventory []models.Inventory

	result := h.db.
		Preload("Produk").
		Preload("Produk.Satuan").
		Preload("Gudang").
		Find(&inventory)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	var response []map[string]interface{}
	for _, item := range inventory {
		jenisSatuan := item.Produk.Satuan.JenisSatuan
		if jenisSatuan == "" {
			jenisSatuan = "N/A"
		}

		response = append(response, map[string]interface{}{
			"id_inventory": item.IdInventory,
			"nama_produk":  item.Produk.NamaProduk,
			"kode_produk":  item.Produk.KodeProduk,
			"volume":       item.Volume,
			"jenis_satuan": jenisSatuan,
			"gudang":       item.Gudang.NamaGudang,
			"idGudang":     item.IdGudang,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "All Inventory retrieved successfully",
		"data":    response,
	})
}

func (h *WMSHandler) GetQualityControl(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	gudangID := c.Query("gudang_id")
	if gudangID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "gudang_id diperlukan"})
		return
	}

	type QCResponse struct {
		IdQC       int       `json:"id_qc"`
		NamaProduk string    `json:"nama_produk"`
		KodeProduk string    `json:"kode_produk"`
		Volume     int       `json:"volume"`
		StatusQC   string    `json:"status_qc"`
		Catatan    string    `json:"catatan"`
		TglQC      time.Time `json:"tanggal_qc"`
	}

	qcs := []QCResponse{}

	result := h.db.Table("quality_control").
		Joins("LEFT JOIN orders ON orders.idOrders = quality_control.idOrders").
		Joins("LEFT JOIN produk ON produk.idProduk = orders.idProduk").
		Where("quality_control.idGudang = ?", gudangID). // ⬅ Pakai ini saja
		Order("quality_control.idQC DESC").
		Scan(&qcs)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	if qcs == nil {
		qcs = []QCResponse{}
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Quality Control retrieved successfully",
		"data":    qcs,
	})
}

func (h *WMSHandler) AddQualityControl(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	var input struct {
		IdOrders int    `json:"idOrders" binding:"required"`
		IdGudang int    `json:"idGudang" binding:"required"`
		Catatan  string `json:"catatan"`
		StatusQC string `json:"status_qc" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	newQC := models.QualityControl{
		IdOrders: input.IdOrders,
		IdGudang: input.IdGudang,
		Catatan:  input.Catatan,
		StatusQC: input.StatusQC,
		TglQC:    time.Now(),
	}

	if err := h.db.Create(&newQC).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menambahkan Quality Control"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Quality Control berhasil ditambahkan",
		"data":    newQC,
	})
}

func (h *WMSHandler) ProcessQC(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	var input struct {
		IdQC      int    `json:"id_qc" binding:"required"`
		QtyGood   int    `json:"qty_good"`
		QtyBad    int    `json:"qty_bad"`
		CatatanQC string `json:"catatan_qc"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	var qc models.QualityControl
	if err := tx.Preload("Orders").Where("idQC = ?", input.IdQC).First(&qc).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusNotFound, gin.H{"error": "QC tidak ditemukan"})
		return
	}

	if input.QtyGood+input.QtyBad != qc.Orders.Volume {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": "Total qty good + bad harus sama dengan volume"})
		return
	}

	if input.QtyGood > 0 {
		var inventory models.Inventory
		err := tx.Where("idProduk = ? AND idGudang = ?", qc.Orders.IdProduk, qc.IdGudang).First(&inventory).Error
		if errors.Is(err, gorm.ErrRecordNotFound) {
			newInventory := models.Inventory{
				IdProduk: qc.Orders.IdProduk,
				IdGudang: qc.IdGudang,
				Volume:   input.QtyGood,
			}
			if err := tx.Create(&newInventory).Error; err != nil {
				tx.Rollback()
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menambah inventory"})
				return
			}
		} else {
			inventory.Volume += input.QtyGood
			if err := tx.Save(&inventory).Error; err != nil {
				tx.Rollback()
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal update inventory"})
				return
			}
		}
	}

	if input.QtyBad > 0 {
		returnItem := models.Return{
			IdQC:      qc.IdQC,
			IdGudang:  qc.IdGudang,
			Volume:    input.QtyBad,
			Alasan:    input.CatatanQC,
			TglReturn: time.Now(),
		}
		if err := tx.Create(&returnItem).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menambah return"})
			return
		}
	}

	qc.StatusQC = "done"
	if err := tx.Save(&qc).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal update QC"})
		return
	}

	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal commit transaction"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "QC berhasil diproses"})
}

func (h *WMSHandler) GetReturn(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	gudangID := c.Query("gudang_id")
	if gudangID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "gudang_id diperlukan"})
		return
	}

	fmt.Printf("🔍 GetReturn dipanggil dengan gudang_id: %s\n", gudangID)

	type ReturnResponse struct {
		IdReturn   int       `json:"id_return"`
		NamaProduk string    `json:"nama_produk"`
		KodeProduk string    `json:"kode_produk"`
		Volume     int       `json:"volume"`
		Alasan     string    `json:"alasan"`
		TglReturn  time.Time `json:"tgl_return"`
	}

	returns := []ReturnResponse{}

	result := h.db.Table("return").
		Select("return.idReturn as id_return, produk.nama_produk, produk.kode_produk, return.volume, return.alasan, return.tgl_return").
		Joins("LEFT JOIN quality_control ON quality_control.idQC = return.idQC").
		Joins("LEFT JOIN orders ON orders.idOrders = quality_control.idOrders").
		Joins("LEFT JOIN produk ON produk.idProduk = orders.idProduk").
		Where("return.idGudang = ?", gudangID).
		Order("return.idReturn DESC").
		Scan(&returns)

	fmt.Printf("📦 Query result: %d returns found for gudang %s\n", len(returns), gudangID)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	if returns == nil {
		returns = []ReturnResponse{}
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Return retrieved successfully",
		"data":    returns,
	})
}

func (h *WMSHandler) GetTransactionChart(c *gin.Context) {

	userID := c.GetUint("user_id")
	role := c.GetInt("role")

	fmt.Println("UserID:", userID)
	fmt.Println("Role Gudang:", role)

	year := c.Query("year")
	if year == "" {
		year = fmt.Sprintf("%d", time.Now().Year())
	}

	type ChartData struct {
		Bulan    int `json:"bulan"`
		Inbound  int `json:"inbound"`
		Outbound int `json:"outbound"`
	}

	chartData := make([]ChartData, 12)
	for i := 0; i < 12; i++ {
		chartData[i] = ChartData{Bulan: i + 1, Inbound: 0, Outbound: 0}
	}

	// Query Inbound (status != 'outbound' OR status IS NULL)
	var inboundData []struct {
		Bulan int `json:"bulan"`
		Total int `json:"total"`
	}
	h.db.Table("orders").
		Select("MONTH(tgl) as bulan, COUNT(*) as total").
		Where("YEAR(tgl) = ? AND (status != 'outbound' OR status IS NULL)", year).
		Group("MONTH(tgl)").
		Scan(&inboundData)

	// Query Outbound (status = 'outbound')
	var outboundData []struct {
		Bulan int `json:"bulan"`
		Total int `json:"total"`
	}
	h.db.Table("orders").
		Select("MONTH(tgl) as bulan, COUNT(*) as total").
		Where("YEAR(tgl) = ? AND status = 'outbound'", year).
		Group("MONTH(tgl)").
		Scan(&outboundData)

	// Populate data
	for _, item := range inboundData {
		if item.Bulan >= 1 && item.Bulan <= 12 {
			chartData[item.Bulan-1].Inbound = item.Total
		}
	}

	for _, item := range outboundData {
		if item.Bulan >= 1 && item.Bulan <= 12 {
			chartData[item.Bulan-1].Outbound = item.Total
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Chart data retrieved successfully",
		"year":    year,
		"data":    chartData,
	})
}
