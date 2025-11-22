package models

type Produk struct {
	IdProduk   int    `gorm:"column:idProduk;primaryKey" json:"id_produk"`
	KodeProduk string `gorm:"column:kode_produk" json:"kode_produk"`
	NamaProduk string `gorm:"column:nama_produk" json:"nama_produk"`
	Volume     int    `gorm:"column:volume" json:"volume"`
	IdSatuan   int    `gorm:"column:idSatuan" json:"id_satuan"`
}

func (Produk) TableName() string {
	return "Produk"
}
