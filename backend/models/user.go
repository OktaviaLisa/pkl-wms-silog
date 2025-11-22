package models

import "time"

type Users struct {
	IDUser     uint      `gorm:"column:idUser;primaryKey;autoIncrement" json:"idUser"`
	Email      string    `gorm:"column:email" json:"email"`
	Username   string    `gorm:"column:username" json:"username"`
	Password   string    `gorm:"column:password" json:"password"`
	CreatedAt  time.Time `gorm:"column:created_at" json:"created_at"`
	RoleGudang int       `gorm:"column:role_gudang" json:"role_gudang"` // ← Kolom baru

	Gudang Gudang `gorm:"foreignKey:RoleGudang;references:IdGudang" json:"gudang_obj,omitempty"`
}

func (Users) TableName() string {
	return "users"
}
