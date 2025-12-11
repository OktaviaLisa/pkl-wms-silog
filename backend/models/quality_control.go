package models

import "time"

type QualityControl struct {
	IdQC     int       `gorm:"column:idQC;primaryKey;autoIncrement" json:"idQc"`
	IdOrders int       `gorm:"column:idOrders" json:"id_orders"`
	Catatan  string    `gorm:"column:catatan" json:"catatan"`
	TglQC    time.Time `gorm:"column:tgl_qc" json:"tgl_qc"`
	StatusQC string    `gorm:"column:status_qc" json:"status_qc"`
	IdGudang int       `gorm:"column:idGudang" json:"id_gudang"`

	Orders Orders `gorm:"foreignKey:IdOrders;references:IdOrders" json:"orders"`
	Gudang Gudang `gorm:"foreignKey:IdGudang;references:IdGudang" json:"gudang"`
}

func (QualityControl) TableName() string {
	return "quality_control"
}
