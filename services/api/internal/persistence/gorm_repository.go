package persistence

import (
	"context"
	"database/sql"
	"errors"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type GORMRepository struct {
	db *gorm.DB
}

func OpenGORM(dsn string) (*gorm.DB, error) {
	return gorm.Open(postgres.Open(dsn), &gorm.Config{})
}

func CloseGORM(db *gorm.DB) error {
	if db == nil {
		return nil
	}
	sqlDB, err := db.DB()
	if err != nil {
		return err
	}
	return sqlDB.Close()
}

func NewGORMRepository(db *gorm.DB) *GORMRepository {
	return &GORMRepository{db: db}
}

func (repo *GORMRepository) Migrate(ctx context.Context) error {
	return repo.db.WithContext(ctx).AutoMigrate(&userRecord{}, &articleRecord{})
}

func (repo *GORMRepository) CreateUser(ctx context.Context, user User) error {
	return repo.db.WithContext(ctx).Create(userRecordFromDomain(user)).Error
}

func (repo *GORMRepository) GetUser(ctx context.Context, id string) (User, error) {
	var record userRecord
	if err := repo.db.WithContext(ctx).First(&record, "id = ?", id).Error; err != nil {
		return User{}, err
	}
	return record.toDomain(), nil
}

func (repo *GORMRepository) UpsertArticle(ctx context.Context, article Article) error {
	var count int64
	if err := repo.db.WithContext(ctx).Model(&userRecord{}).Where("id = ?", article.AuthorID).Count(&count).Error; err != nil {
		return err
	}
	if count == 0 {
		return ErrAuthorNotFound
	}

	record := articleRecordFromDomain(article)
	return repo.db.WithContext(ctx).Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "id"}},
		DoUpdates: clause.AssignmentColumns([]string{
			"author_id",
			"slug",
			"title",
			"body_markdown",
			"published",
			"published_at",
			"updated_at",
		}),
	}).Create(record).Error
}

func (repo *GORMRepository) GetArticle(ctx context.Context, id string) (Article, error) {
	var record articleRecord
	if err := repo.db.WithContext(ctx).First(&record, "id = ?", id).Error; err != nil {
		return Article{}, err
	}
	return record.toDomain(), nil
}

func (repo *GORMRepository) ListArticlesByAuthor(ctx context.Context, authorID string, opts ListOptions) ([]Article, error) {
	limit := opts.Limit
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	var records []articleRecord
	if err := repo.db.WithContext(ctx).
		Where("author_id = ?", authorID).
		Order("created_at desc, id desc").
		Limit(limit).
		Find(&records).Error; err != nil {
		return nil, err
	}
	articles := make([]Article, 0, len(records))
	for _, record := range records {
		articles = append(articles, record.toDomain())
	}
	return articles, nil
}

func IsNotFound(err error) bool {
	return errors.Is(err, gorm.ErrRecordNotFound) || errors.Is(err, sql.ErrNoRows)
}
