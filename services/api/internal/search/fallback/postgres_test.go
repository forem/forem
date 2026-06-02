package fallback_test

import (
	"context"
	"errors"
	"testing"

	"github.com/agentwego/noema/services/api/internal/search"
	"github.com/agentwego/noema/services/api/internal/search/fallback"
)

func TestPostgresProviderIsDegradedReadOnlyFallback(t *testing.T) {
	provider := fallback.NewPostgresProvider()

	result, err := provider.Search(context.Background(), search.SearchRequest{Query: "中文 english", Limit: 10})
	if err != nil {
		t.Fatalf("Search returned error: %v", err)
	}
	if result.Provider != "postgres" {
		t.Fatalf("Provider = %q, want postgres", result.Provider)
	}
	if len(result.Hits) != 0 {
		t.Fatalf("fallback stub returned %d hits, want zero until DB wiring exists", len(result.Hits))
	}
}

func TestPostgresProviderRejectsIndexMutationMethods(t *testing.T) {
	provider := fallback.NewPostgresProvider()

	mutationChecks := []struct {
		name string
		err  error
	}{
		{name: "EnsureIndexes", err: provider.EnsureIndexes(context.Background())},
		{name: "UpsertArticle", err: provider.UpsertArticle(context.Background(), search.ArticleDocument{ID: "a1"})},
		{name: "DeleteArticle", err: provider.DeleteArticle(context.Background(), "a1")},
		{name: "UpsertComment", err: provider.UpsertComment(context.Background(), search.CommentDocument{ID: "c1"})},
		{name: "DeleteComment", err: provider.DeleteComment(context.Background(), "c1")},
		{name: "UpsertUser", err: provider.UpsertUser(context.Background(), search.UserDocument{ID: "u1"})},
		{name: "UpsertTag", err: provider.UpsertTag(context.Background(), search.TagDocument{ID: "t1"})},
		{name: "BulkIndex", err: provider.BulkIndex(context.Background(), []search.Document{search.ArticleDocument{ID: "a1"}})},
	}

	for _, check := range mutationChecks {
		if !errors.Is(check.err, fallback.ErrReadOnly) {
			t.Fatalf("%s error = %v, want ErrReadOnly", check.name, check.err)
		}
	}
}

func TestNewProviderSelectsNoopPostgresOrRejectsUnknownProvider(t *testing.T) {
	noop, err := search.NewProvider("", search.ProviderOptions{})
	if err != nil {
		t.Fatalf("default provider returned error: %v", err)
	}
	noopResult, err := noop.Search(context.Background(), search.SearchRequest{})
	if err != nil || noopResult.Provider != "noop" {
		t.Fatalf("default provider = %#v err=%v, want noop", noopResult, err)
	}

	postgres, err := search.NewProvider("postgres", search.ProviderOptions{})
	if err != nil {
		t.Fatalf("postgres provider returned error: %v", err)
	}
	postgresResult, err := postgres.Search(context.Background(), search.SearchRequest{})
	if err != nil || postgresResult.Provider != "postgres" {
		t.Fatalf("postgres provider = %#v err=%v, want postgres", postgresResult, err)
	}

	if _, err := search.NewProvider("elasticsearch", search.ProviderOptions{}); err == nil {
		t.Fatal("expected elasticsearch provider to be unavailable until real adapter wiring exists")
	}
	if _, err := search.NewProvider("unknown", search.ProviderOptions{}); err == nil {
		t.Fatal("expected unknown provider error")
	}
}
