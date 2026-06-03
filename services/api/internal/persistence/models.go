package persistence

import "time"

type userRecord struct {
	ID          string `gorm:"primaryKey;type:text"`
	Username    string `gorm:"not null;uniqueIndex;type:text"`
	DisplayName string `gorm:"not null;type:text"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

func (userRecord) TableName() string { return "noema_users" }

type articleRecord struct {
	ID           string     `gorm:"primaryKey;type:text"`
	AuthorID     string     `gorm:"not null;index;type:text"`
	Author       userRecord `gorm:"foreignKey:AuthorID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT"`
	Slug         string     `gorm:"not null;uniqueIndex;type:text"`
	Title        string     `gorm:"not null;type:text"`
	BodyMarkdown string     `gorm:"not null;type:text"`
	Published    bool       `gorm:"not null;default:false"`
	PublishedAt  *time.Time
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

func (articleRecord) TableName() string { return "noema_articles" }

func userRecordFromDomain(user User) *userRecord {
	return &userRecord{
		ID:          user.ID,
		Username:    user.Username,
		DisplayName: user.DisplayName,
		CreatedAt:   user.CreatedAt,
		UpdatedAt:   user.UpdatedAt,
	}
}

func (record userRecord) toDomain() User {
	return User{
		ID:          record.ID,
		Username:    record.Username,
		DisplayName: record.DisplayName,
		CreatedAt:   record.CreatedAt,
		UpdatedAt:   record.UpdatedAt,
	}
}

func articleRecordFromDomain(article Article) *articleRecord {
	return &articleRecord{
		ID:           article.ID,
		AuthorID:     article.AuthorID,
		Slug:         article.Slug,
		Title:        article.Title,
		BodyMarkdown: article.BodyMarkdown,
		Published:    article.Published,
		PublishedAt:  article.PublishedAt,
		CreatedAt:    article.CreatedAt,
		UpdatedAt:    article.UpdatedAt,
	}
}

func (record articleRecord) toDomain() Article {
	return Article{
		ID:           record.ID,
		AuthorID:     record.AuthorID,
		Slug:         record.Slug,
		Title:        record.Title,
		BodyMarkdown: record.BodyMarkdown,
		Published:    record.Published,
		PublishedAt:  record.PublishedAt,
		CreatedAt:    record.CreatedAt,
		UpdatedAt:    record.UpdatedAt,
	}
}
