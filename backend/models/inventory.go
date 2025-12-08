package models

import "backend/config"

type Inventory struct {
	IdInventory int `gorm:"column:idInventory;primaryKey" json:"id_inventory"`
	IdProduk    int `gorm:"column:idProduk" json:"id_produk"`
	IdGudang    int `gorm:"column:idGudang" json:"id_gudang"`
	Volume      int `gorm:"column:volume" json:"volume"`

	Produk Produk `gorm:"foreignKey:IdProduk;references:IdProduk" json:"produk"`
	Gudang Gudang `gorm:"foreignKey:IdGudang;references:IdGudang" json:"gudang"`
}

func (Inventory) TableName() string {
	return "inventory"
}

func GetAllInventory() ([]Inventory, error) {
	var inventories []Inventory

	result := config.DB.
    Preload("Produk").
    Preload("Produk.Satuan"). 
    Preload("Gudang").
    Find(&inventories)

	return inventories, result.Error
}

