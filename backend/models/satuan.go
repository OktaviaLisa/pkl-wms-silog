package models

type Satuan struct {
	IDSatuan    int    `gorm:"column:idSatuan;primaryKey" json:"id_satuan"`
	JenisSatuan string `gorm:"column:jenis_satuan" json:"jenis_satuan"`
}

func (Satuan) TableName() string {
	return "satuan"
}
