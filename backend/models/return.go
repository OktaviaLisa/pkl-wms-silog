package models

import "time"

type Return struct {
	IdReturn  int       `gorm:"column:idReturn;primaryKey;autoIncrement" json:"id_return"`
	IdQC      int       `gorm:"column:idQC" json:"id_qc"`
	IdGudang  int       `gorm:"column:idGudang" json:"id_gudang"`
	Volume    int       `gorm:"column:volume" json:"volume"`
	Alasan    string    `gorm:"column:alasan" json:"alasan"`
	TglReturn time.Time `gorm:"column:tgl_return" json:"tgl_return"`

	QC     QualityControl `gorm:"foreignKey:IdQC;references:IdQC" json:"qc"`
	Gudang Gudang         `gorm:"foreignKey:IdGudang;references:IdGudang" json:"gudang"`
}

func (Return) TableName() string {
	return "return"
}
