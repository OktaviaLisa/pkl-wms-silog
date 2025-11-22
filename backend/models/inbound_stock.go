package models

import "time"

type Inbound_Stock struct {
	IdInbound int `gorm:"column:idInbound;primaryKey" json:"idInbound"`
	IdProduk  int `gorm:"column:idProduk" json:"idProduk"`

	// JSON TAG DIPISAH dari relasi
	GudangAsalId   int `gorm:"column:gudang_asal" json:"gudang_asal"`
	GudangTujuanId int `gorm:"column:gudang_tujuan" json:"gudang_tujuan"`

	TanggalMasuk time.Time `gorm:"column:tgl_masuk" json:"tanggal_masuk"`
	Deskripsi    string    `gorm:"column:deskripsi" json:"deskripsi"`

	// RELASI – JSON TAG dengan nama berbeda untuk output
	GudangAsal   Gudang `gorm:"foreignKey:GudangAsalId;references:IdGudang" json:"gudang_asal_obj,omitempty"`
	GudangTujuan Gudang `gorm:"foreignKey:GudangTujuanId;references:IdGudang" json:"gudang_tujuan_obj,omitempty"`
	Produk       Produk `gorm:"foreignKey:IdProduk;references:IdProduk" json:"produk_obj,omitempty"`
}

func (Inbound_Stock) TableName() string {
	return "inbound_stock"
}
