package models

type Gudang struct {
	IdGudang   int    `gorm:"column:idGudang;primaryKey" json:"idGudang"`
	NamaGudang string `gorm:"column:nama_gudang" json:"nama_gudang"`
	Alamat     string `gorm:"column:alamat" json:"alamat"`
}

func (Gudang) TableName() string {
	return "gudang"
}
