package models

import "time"

type Outbound struct {
	IDOutbound   uint   `gorm:"column:idOutbound;primaryKey;autoIncrement" json:"idOutbound"`
	IDProduk     uint   `gorm:"column:idProduk" json:"idProduk"`
	GudangAsal   uint   `gorm:"column:gudang_asal" json:"gudang_asal"`
	GudangTujuan uint   `gorm:"column:gudang_tujuan" json:"gudang_tujuan"`
	TglKeluar    time.Time `gorm:"column:tgl_keluar" json:"tgl_keluar"`
	Deskripsi    string `gorm:"column:deskripsi" json:"deskripsi"`

	// RELASI untuk JOIN dengan tabel lain
	Produk       Produk `gorm:"foreignKey:IDProduk;references:IdProduk" json:"produk_obj,omitempty"`
	GudangAsalObj   Gudang `gorm:"foreignKey:GudangAsal;references:IdGudang" json:"gudang_asal_obj,omitempty"`
	GudangTujuanObj Gudang `gorm:"foreignKey:GudangTujuan;references:IdGudang" json:"gudang_tujuan_obj,omitempty"`
}

func (Outbound) TableName() string {
	return "outbound_stock"
}
