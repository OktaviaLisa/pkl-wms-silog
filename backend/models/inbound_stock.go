package models

import "time"

type Orders struct {
	IdOrders int `gorm:"column:idOrders;primaryKey" json:"idOrders"`
	IdProduk int `gorm:"column:idProduk" json:"idProduk"`

	// JSON TAG DIPISAH dari relasi
	GudangAsalId   int `gorm:"column:gudang_asal" json:"gudang_asal"`
	GudangTujuanId int `gorm:"column:gudang_tujuan" json:"gudang_tujuan"`

	TanggalMasuk time.Time `gorm:"column:tgl" json:"tanggal"`
	Deskripsi    string    `gorm:"column:deskripsi" json:"deskripsi"`

	// RELASI – JSON TAG dengan nama berbeda untuk output
	GudangAsal   Gudang `gorm:"foreignKey:GudangAsalId;references:IdGudang" json:"gudang_asal_obj,omitempty"`
	GudangTujuan Gudang `gorm:"foreignKey:GudangTujuanId;references:IdGudang" json:"gudang_tujuan_obj,omitempty"`
	Produk       Produk `gorm:"foreignKey:IdProduk;references:IdProduk" json:"produk_obj,omitempty"`
}

func (Orders) TableName() string {
	return "Orders"
}
