package legacyimport_test

import (
	"encoding/json"
	"os"
	"testing"
	"time"

	"github.com/agentwego/noema/services/api/internal/legacyimport"
)

func TestMapForemUserToCleanDomainDTO(t *testing.T) {
	createdAt := time.Date(2026, 6, 3, 0, 0, 0, 0, time.UTC)
	updatedAt := time.Date(2026, 6, 3, 1, 30, 0, 0, time.UTC)

	dto, err := legacyimport.MapForemUser(legacyimport.ForemUser{
		ID:           42,
		Username:     "alice",
		Name:         "Alice Example",
		ProfileImage: "https://example.com/avatar.png",
		CreatedAt:    createdAt,
		UpdatedAt:    updatedAt,
	})
	if err != nil {
		t.Fatalf("MapForemUser returned error: %v", err)
	}
	if dto.ID != "42" || dto.Username != "alice" || dto.DisplayName != "Alice Example" {
		t.Fatalf("unexpected user dto: %+v", dto)
	}
	if dto.ProfileImage != "https://example.com/avatar.png" {
		t.Fatalf("expected profile image to be preserved, got %q", dto.ProfileImage)
	}
	if !dto.CreatedAt.Equal(createdAt) || !dto.UpdatedAt.Equal(updatedAt) {
		t.Fatalf("timestamps were not preserved: %+v", dto)
	}

	user := dto.ToPersistence()
	if user.ID != "42" || user.Username != "alice" || user.DisplayName != "Alice Example" {
		t.Fatalf("unexpected persistence user: %+v", user)
	}

	doc := dto.ToSearchDocument()
	if doc.ID != "42" || doc.Username != "alice" || doc.Name != "Alice Example" {
		t.Fatalf("unexpected search user document: %+v", doc)
	}
}

func TestMapForemArticleToCleanDomainDTOFromFixture(t *testing.T) {
	payload := readFixture(t)

	userDTO, err := legacyimport.MapForemUser(payload.Article.User)
	if err != nil {
		t.Fatalf("MapForemUser returned error: %v", err)
	}
	articleDTO, err := legacyimport.MapForemArticle(payload.Article)
	if err != nil {
		t.Fatalf("MapForemArticle returned error: %v", err)
	}

	if articleDTO.ID != "123456" || articleDTO.AuthorID != userDTO.ID {
		t.Fatalf("unexpected article ids: article=%+v user=%+v", articleDTO, userDTO)
	}
	if articleDTO.Slug != "hello-noema" || articleDTO.Title != "Hello Noema" {
		t.Fatalf("unexpected article identity fields: %+v", articleDTO)
	}
	if articleDTO.BodyMarkdown != "## Intro\n\nNative article body." {
		t.Fatalf("unexpected body markdown: %q", articleDTO.BodyMarkdown)
	}
	if !articleDTO.Published || articleDTO.PublishedAt == nil {
		t.Fatalf("expected published article with published_at: %+v", articleDTO)
	}
	if got := articleDTO.PublishedAt.Format(time.RFC3339); got != "2026-06-03T01:00:00Z" {
		t.Fatalf("unexpected published_at: %s", got)
	}
	if len(articleDTO.Tags) != 2 || articleDTO.Tags[0] != "go" || articleDTO.Tags[1] != "native" {
		t.Fatalf("tags were not preserved: %+v", articleDTO.Tags)
	}

	article := articleDTO.ToPersistence()
	if article.ID != "123456" || article.AuthorID != "42" || article.Title != "Hello Noema" {
		t.Fatalf("unexpected persistence article: %+v", article)
	}

	doc := articleDTO.ToSearchDocument()
	if doc.ID != "123456" || doc.Title != "Hello Noema" {
		t.Fatalf("unexpected search article document: %+v", doc)
	}
}

func TestMapForemArticleRejectsMissingRequiredFields(t *testing.T) {
	_, err := legacyimport.MapForemArticle(legacyimport.ForemArticle{
		ID:           123,
		UserID:       42,
		Title:        "Missing slug",
		BodyMarkdown: "body",
	})
	if err == nil {
		t.Fatal("expected missing slug to be rejected")
	}
}

type fixturePayload struct {
	Article legacyimport.ForemArticle `json:"article"`
}

func readFixture(t *testing.T) fixturePayload {
	t.Helper()
	bytes, err := os.ReadFile("testdata/forem_article_with_user.json")
	if err != nil {
		t.Fatalf("read fixture: %v", err)
	}
	var payload fixturePayload
	if err := json.Unmarshal(bytes, &payload); err != nil {
		t.Fatalf("decode fixture: %v", err)
	}
	return payload
}
