package persistence_test

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/agentwego/noema/services/api/internal/persistence"
)

func TestGORMRepositoryPersistsArticleWithAuthor(t *testing.T) {
	repo := newPostgresRepository(t)
	ctx := context.Background()

	now := time.Date(2026, 6, 3, 1, 0, 0, 0, time.UTC)
	user := persistence.User{
		ID:          uniqueID("usr"),
		Username:    "alice",
		DisplayName: "Alice Example",
	}
	article := persistence.Article{
		ID:           uniqueID("art"),
		AuthorID:     user.ID,
		Slug:         "hello-noema-native",
		Title:        "Hello Noema Native",
		BodyMarkdown: "Noema-native article persistence starts as a clean domain seam.",
		Published:    true,
		PublishedAt:  &now,
	}

	if err := repo.CreateUser(ctx, user); err != nil {
		t.Fatalf("CreateUser() error = %v", err)
	}
	if err := repo.UpsertArticle(ctx, article); err != nil {
		t.Fatalf("UpsertArticle() error = %v", err)
	}

	gotUser, err := repo.GetUser(ctx, user.ID)
	if err != nil {
		t.Fatalf("GetUser() error = %v", err)
	}
	if gotUser.Username != user.Username || gotUser.DisplayName != user.DisplayName {
		t.Fatalf("GetUser() = %#v, want username/display name from %#v", gotUser, user)
	}

	gotArticle, err := repo.GetArticle(ctx, article.ID)
	if err != nil {
		t.Fatalf("GetArticle() error = %v", err)
	}
	if gotArticle.AuthorID != user.ID || gotArticle.Slug != article.Slug || gotArticle.Title != article.Title || !gotArticle.Published {
		t.Fatalf("GetArticle() = %#v, want persisted article %#v", gotArticle, article)
	}
	if gotArticle.PublishedAt == nil || !gotArticle.PublishedAt.Equal(now) {
		t.Fatalf("PublishedAt = %v, want %v", gotArticle.PublishedAt, now)
	}
	if gotArticle.CreatedAt.IsZero() || gotArticle.UpdatedAt.IsZero() {
		t.Fatalf("timestamps were not populated: created=%v updated=%v", gotArticle.CreatedAt, gotArticle.UpdatedAt)
	}

	articles, err := repo.ListArticlesByAuthor(ctx, user.ID, persistence.ListOptions{Limit: 10})
	if err != nil {
		t.Fatalf("ListArticlesByAuthor() error = %v", err)
	}
	if len(articles) != 1 || articles[0].ID != article.ID {
		t.Fatalf("ListArticlesByAuthor() = %#v, want exactly article %s", articles, article.ID)
	}
}

func TestGORMRepositoryRejectsArticleWithoutExistingAuthor(t *testing.T) {
	repo := newPostgresRepository(t)
	ctx := context.Background()

	err := repo.UpsertArticle(ctx, persistence.Article{
		ID:           uniqueID("art"),
		AuthorID:     uniqueID("missing_user"),
		Slug:         "orphaned-article",
		Title:        "Orphaned Article",
		BodyMarkdown: "This must not be accepted by the native persistence seam.",
	})
	if !errors.Is(err, persistence.ErrAuthorNotFound) {
		t.Fatalf("UpsertArticle() error = %v, want ErrAuthorNotFound", err)
	}
}

func newPostgresRepository(t *testing.T) persistence.Repository {
	t.Helper()
	dsn := os.Getenv("NOEMA_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("NOEMA_TEST_DATABASE_URL is unset; set it to a disposable local PostgreSQL database to run persistence integration tests")
	}
	db, err := persistence.OpenGORM(dsn)
	if err != nil {
		t.Fatalf("OpenGORM() error = %v", err)
	}
	t.Cleanup(func() { _ = persistence.CloseGORM(db) })

	repo := persistence.NewGORMRepository(db)
	if err := repo.Migrate(context.Background()); err != nil {
		t.Fatalf("Migrate() error = %v", err)
	}
	return repo
}

func uniqueID(prefix string) string {
	return fmt.Sprintf("%s_%d", prefix, time.Now().UnixNano())
}
