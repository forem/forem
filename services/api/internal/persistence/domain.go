package persistence

import (
	"context"
	"errors"
	"time"
)

var ErrAuthorNotFound = errors.New("article author not found")

// User is the minimal Noema-native identity record needed by the first
// persistence seam. It intentionally avoids line-porting Forem's large
// ActiveRecord User model.
type User struct {
	ID          string
	Username    string
	DisplayName string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// Article is the minimal Noema-native content record needed by the first
// persistence seam. Search documents and feed semantics can derive from this
// source-of-truth shape in later slices.
type Article struct {
	ID           string
	AuthorID     string
	Slug         string
	Title        string
	BodyMarkdown string
	Published    bool
	PublishedAt  *time.Time
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

type ListOptions struct {
	Limit int
}

type Repository interface {
	CreateUser(ctx context.Context, user User) error
	GetUser(ctx context.Context, id string) (User, error)
	UpsertArticle(ctx context.Context, article Article) error
	GetArticle(ctx context.Context, id string) (Article, error)
	ListArticlesByAuthor(ctx context.Context, authorID string, opts ListOptions) ([]Article, error)
}
