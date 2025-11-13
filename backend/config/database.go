package config

import (
	"fmt"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDatabase() {
	// Format DSN MySQL/MariaDB:
	// user:password@tcp(host:port)/nama_db?charset=utf8mb4&parseTime=True&loc=Local
	dsn := "root:@tcp(127.0.0.1:3306)/pkl_wms?charset=utf8mb4&parseTime=True&loc=Local"

	database, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		panic("❌ Gagal konek ke database: " + err.Error())
	}

	DB = database
	fmt.Println("✅ Koneksi MariaDB berhasil!")
}
