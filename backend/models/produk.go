package models

type Produk struct {
	IdProduk   int    `gorm:"column:idProduk;primaryKey" json:"id_produk"`
	KodeProduk string `gorm:"column:kode_produk" json:"kode_produk"`
	NamaProduk string `gorm:"column:nama_produk" json:"nama_produk"`
	IdSatuan   int    `gorm:"column:idSatuan" json:"id_satuan"`

	Satuan Satuan `gorm:"foreignKey:IdSatuan;references:IDSatuan" json:"satuan"`
}

func (Produk) TableName() string {
	return "produk"
}
