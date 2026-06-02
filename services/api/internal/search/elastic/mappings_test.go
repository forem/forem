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
