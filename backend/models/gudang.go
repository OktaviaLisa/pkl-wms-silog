package models

type Gudang struct {
	IdGudang   int    `gorm:"column:idGudang;primaryKey" json:"id_gudang"`
	NamaGudang string `gorm:"column:nama_gudang" json:"nama_gudang"`
	Alamat     string `gorm:"column:alamat_gudang" json:"alamat_gudang"`
}

func (Gudang) TableName() string {
	return "gudang"
}
