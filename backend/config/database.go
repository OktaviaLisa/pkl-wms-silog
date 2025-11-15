package config

import (
	"fmt"
	"log"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var DB *gorm.DB

// ConnectDatabase membuka koneksi DB dan mengembalikan *gorm.DB
func ConnectDatabase() *gorm.DB {

	// Format DSN MySQL/MariaDB
	dsn := "root:@tcp(127.0.0.1:3306)/pkl_wms?charset=utf8mb4&parseTime=True&loc=Local"

	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("❌ Gagal konek ke database: ", err)
	}

	DB = db
	fmt.Println("✅ Koneksi MariaDB berhasil!")

	return DB
}
