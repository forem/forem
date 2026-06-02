package search_test

import (
	"context"
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

	if err := provider.EnsureIndexes(context.Background()); err != nil {
		t.Fatalf("EnsureIndexes returned error: %v", err)
	}

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
