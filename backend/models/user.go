package models

type Users struct {
	ID       uint   `gorm:"primaryKey;autoIncrement" json:"iduser"`
	Username string `json:"username"`
	Password string `json:"password"`
	Email    string `json:"email"`
}
