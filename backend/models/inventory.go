package models

type Inventory struct {
	IdInventory int `gorm:"column:idInventory;primaryKey" json:"id_inventory"`
	IdProduk    int `gorm:"column:idProduk" json:"id_produk"`
	IDGudang    int `gorm:"column:idGudang" json:"id_gudang"`
	Jumlah      int `gorm:"column:jumlah" json:"jumlah"`

	Produk Produk `gorm:"foreignKey:IdProduk;references:IdProduk" json:"produk"`
	Gudang Gudang `gorm:"foreignKey:IDGudang;references:IdGudang" json:"gudang"`
}

func (Inventory) TableName() string {
	return "inventory"
}
