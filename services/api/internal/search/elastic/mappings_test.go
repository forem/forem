package elastic_test

import (
	"encoding/json"
	"testing"

	"github.com/agentwego/noema/services/api/internal/search"
	"github.com/agentwego/noema/services/api/internal/search/elastic"
)

func TestArticleIndexSpecUsesVersionedIndexAndReadAlias(t *testing.T) {
	family := search.IndexFamily{Prefix: "noema", Version: "v1"}

	spec := elastic.ArticleIndexSpec(family, elastic.AnalyzerNGram)

	if spec.IndexName != "noema-articles-v1" {
		t.Fatalf("IndexName = %q", spec.IndexName)
	}
	if spec.ReadAlias != "noema-articles-read" {
		t.Fatalf("ReadAlias = %q", spec.ReadAlias)
	}
	if spec.DocumentFamily != search.DocumentFamilyArticles {
		t.Fatalf("DocumentFamily = %q", spec.DocumentFamily)
	}
}

func TestArticleIndexSpecDefinesMixedLanguageNGramAnalyzer(t *testing.T) {
	family := search.IndexFamily{Prefix: "noema", Version: "v1"}

	spec := elastic.ArticleIndexSpec(family, elastic.AnalyzerNGram)
	mapping := spec.Mapping

	analysis := mapping["settings"].(map[string]any)["analysis"].(map[string]any)
	analyzers := analysis["analyzer"].(map[string]any)
	if _, ok := analyzers["noema_mixed_text"].(map[string]any); !ok {
		t.Fatalf("expected noema_mixed_text analyzer in mapping: %#v", analyzers)
	}

	props := mapping["mappings"].(map[string]any)["properties"].(map[string]any)
	for _, field := range []string{"title", "body", "tags", "author_username", "language", "published_at"} {
		if _, ok := props[field]; !ok {
			t.Fatalf("expected article field %q in mapping", field)
		}
	}

	if _, err := json.Marshal(mapping); err != nil {
		t.Fatalf("mapping must be JSON serializable: %v", err)
	}
}

func TestArticleIndexSpecCanSelectIKAnalyzerWithoutClusterSideEffects(t *testing.T) {
	family := search.IndexFamily{Prefix: "noema", Version: "v1"}

	spec := elastic.ArticleIndexSpec(family, elastic.AnalyzerIK)
	analysis := spec.Mapping["settings"].(map[string]any)["analysis"].(map[string]any)
	analyzers := analysis["analyzer"].(map[string]any)
	mixed := analyzers["noema_mixed_text"].(map[string]any)

	if mixed["tokenizer"] != "ik_max_word" {
		t.Fatalf("IK tokenizer = %q, want ik_max_word", mixed["tokenizer"])
	}
}

func TestAllIndexSpecsCoverNativeSearchDocumentFamilies(t *testing.T) {
	family := search.IndexFamily{Prefix: "noema", Version: "v1"}

	specs := elastic.AllIndexSpecs(family, elastic.AnalyzerNGram)

	want := map[string]struct {
		index string
		alias string
	}{
		search.DocumentFamilyArticles: {index: "noema-articles-v1", alias: "noema-articles-read"},
		search.DocumentFamilyComments: {index: "noema-comments-v1", alias: "noema-comments-read"},
		search.DocumentFamilyUsers:    {index: "noema-users-v1", alias: "noema-users-read"},
		search.DocumentFamilyTags:     {index: "noema-tags-v1", alias: "noema-tags-read"},
	}

	if len(specs) != len(want) {
		t.Fatalf("got %d specs, want %d", len(specs), len(want))
	}
	for _, spec := range specs {
		entry, ok := want[spec.DocumentFamily]
		if !ok {
			t.Fatalf("unexpected document family %q", spec.DocumentFamily)
		}
		if spec.IndexName != entry.index || spec.ReadAlias != entry.alias {
			t.Fatalf("%s index/alias = %q/%q, want %q/%q", spec.DocumentFamily, spec.IndexName, spec.ReadAlias, entry.index, entry.alias)
		}
		if _, err := json.Marshal(spec.Mapping); err != nil {
			t.Fatalf("%s mapping must be JSON serializable: %v", spec.DocumentFamily, err)
		}
		delete(want, spec.DocumentFamily)
	}
	if len(want) != 0 {
		t.Fatalf("missing specs for families: %#v", want)
	}
}

func TestCommentUserAndTagIndexSpecsExposeRequiredFields(t *testing.T) {
	family := search.IndexFamily{Prefix: "noema", Version: "v1"}

	cases := []struct {
		name   string
		spec   elastic.IndexSpec
		fields []string
	}{
		{
			name:   "comments",
			spec:   elastic.CommentIndexSpec(family, elastic.AnalyzerNGram),
			fields: []string{"id", "article_id", "body", "author_id", "published", "created_at", "visible"},
		},
		{
			name:   "users",
			spec:   elastic.UserIndexSpec(family, elastic.AnalyzerNGram),
			fields: []string{"id", "username", "name", "summary", "joined_at", "active"},
		},
		{
			name:   "tags",
			spec:   elastic.TagIndexSpec(family, elastic.AnalyzerNGram),
			fields: []string{"id", "name", "hotness_score", "supported", "created_at"},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			props := tc.spec.Mapping["mappings"].(map[string]any)["properties"].(map[string]any)
			for _, field := range tc.fields {
				if _, ok := props[field]; !ok {
					t.Fatalf("expected %s field %q in mapping", tc.name, field)
				}
			}
		})
	}
}
