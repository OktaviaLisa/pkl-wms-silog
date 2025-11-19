package models

import "time"

type Users struct {
	IDUser    uint      `gorm:"column:idUser;primaryKey;autoIncrement" json:"idUser"`
	Username  string    `gorm:"column:username" json:"username"`
	Password  string    `gorm:"column:password" json:"password"`
	Email     string    `gorm:"column:email" json:"email"`
	CreatedAt time.Time `json:"created_at"`
}

// Penting! Karena nama struct = Users, tableName selalu users,
// tapi kita tetap deklarasi agar pasti benar.
func (Users) TableName() string {
	return "users"
}
