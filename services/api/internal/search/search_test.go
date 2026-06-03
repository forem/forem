package search_test

import (
	"context"
	"errors"
	"testing"

	"github.com/agentwego/noema/services/api/internal/search"
)

func TestIndexNamesUsePrefixAndVersionedTargets(t *testing.T) {
	idx := search.IndexFamily{Prefix: "noema", Version: "v1"}

	cases := map[string]string{
		"articles": idx.VersionedIndex(search.DocumentFamilyArticles),
		"comments": idx.VersionedIndex(search.DocumentFamilyComments),
		"users":    idx.VersionedIndex(search.DocumentFamilyUsers),
		"tags":     idx.VersionedIndex(search.DocumentFamilyTags),
	}

	want := map[string]string{
		"articles": "noema-articles-v1",
		"comments": "noema-comments-v1",
		"users":    "noema-users-v1",
		"tags":     "noema-tags-v1",
	}

	for family, got := range cases {
		if got != want[family] {
			t.Fatalf("%s index = %q, want %q", family, got, want[family])
		}
	}
}

func TestReadAliasesUsePrefixAndDocumentFamily(t *testing.T) {
	idx := search.IndexFamily{Prefix: "noema", Version: "v1"}

	if got := idx.ReadAlias(search.DocumentFamilyArticles); got != "noema-articles-read" {
		t.Fatalf("article read alias = %q", got)
	}
	if got := idx.ReadAlias(search.DocumentFamilyTags); got != "noema-tags-read" {
		t.Fatalf("tag read alias = %q", got)
	}
}

func TestNoopProviderIsBootstrapOnlyAndDoesNotTouchExternalSearch(t *testing.T) {
	provider := search.NewNoopProvider()

	result, err := provider.Search(context.Background(), search.SearchRequest{Query: "中文 english", Limit: 10})
	if err != nil {
		t.Fatalf("Search returned error: %v", err)
	}
	if len(result.Hits) != 0 {
		t.Fatalf("noop search returned %d hits, want zero", len(result.Hits))
	}
	if result.Provider != "noop" {
		t.Fatalf("Provider = %q, want noop", result.Provider)
	}
}

func TestNoopProviderRejectsIndexMutationMethods(t *testing.T) {
	provider := search.NewNoopProvider()

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
		if !errors.Is(check.err, search.ErrNoopReadOnly) {
			t.Fatalf("%s error = %v, want ErrNoopReadOnly", check.name, check.err)
		}
	}
}

func TestNormalizeSearchRequestTrimsQueryAndAppliesLimitBounds(t *testing.T) {
	cases := []struct {
		name      string
		req       search.SearchRequest
		wantQuery string
		wantLimit int
	}{
		{name: "default limit", req: search.SearchRequest{Query: "  中文 english  "}, wantQuery: "中文 english", wantLimit: 20},
		{name: "negative limit", req: search.SearchRequest{Query: "tags", Limit: -10}, wantQuery: "tags", wantLimit: 20},
		{name: "explicit limit", req: search.SearchRequest{Query: "articles", Limit: 7}, wantQuery: "articles", wantLimit: 7},
		{name: "max limit", req: search.SearchRequest{Query: "users", Limit: 500}, wantQuery: "users", wantLimit: 100},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := search.NormalizeSearchRequest(tc.req)
			if got.Query != tc.wantQuery || got.Limit != tc.wantLimit {
				t.Fatalf("NormalizeSearchRequest() = query %q limit %d, want query %q limit %d", got.Query, got.Limit, tc.wantQuery, tc.wantLimit)
			}
		})
	}
}

func TestSearchRequestLimitConstantsDocumentLocalContract(t *testing.T) {
	if search.DefaultSearchLimit != 20 {
		t.Fatalf("DefaultSearchLimit = %d, want 20", search.DefaultSearchLimit)
	}
	if search.MaxSearchLimit != 100 {
		t.Fatalf("MaxSearchLimit = %d, want 100", search.MaxSearchLimit)
	}
}
