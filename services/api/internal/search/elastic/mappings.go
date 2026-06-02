package elastic

import "github.com/agentwego/noema/services/api/internal/search"

const (
	AnalyzerNGram = "ngram"
	AnalyzerIK    = "ik"
)

type IndexSpec struct {
	DocumentFamily string
	IndexName      string
	ReadAlias      string
	Mapping        map[string]any
}

func ArticleIndexSpec(family search.IndexFamily, analyzer string) IndexSpec {
	return IndexSpec{
		DocumentFamily: search.DocumentFamilyArticles,
		IndexName:      family.VersionedIndex(search.DocumentFamilyArticles),
		ReadAlias:      family.ReadAlias(search.DocumentFamilyArticles),
		Mapping:        articleMapping(analyzer),
	}
}

func articleMapping(analyzer string) map[string]any {
	return map[string]any{
		"settings": map[string]any{
			"analysis": analysisSettings(analyzer),
		},
		"mappings": map[string]any{
			"dynamic": "strict",
			"properties": map[string]any{
				"id": map[string]any{
					"type": "keyword",
				},
				"path": map[string]any{
					"type": "keyword",
				},
				"title": map[string]any{
					"type":     "text",
					"analyzer": "noema_mixed_text",
					"fields": map[string]any{
						"keyword": map[string]any{"type": "keyword", "ignore_above": 256},
					},
				},
				"body": map[string]any{
					"type":     "text",
					"analyzer": "noema_mixed_text",
				},
				"tags": map[string]any{
					"type": "keyword",
				},
				"author_id": map[string]any{
					"type": "keyword",
				},
				"author_username": map[string]any{
					"type": "keyword",
				},
				"organization_id": map[string]any{
					"type": "keyword",
				},
				"language": map[string]any{
					"type": "keyword",
				},
				"published": map[string]any{
					"type": "boolean",
				},
				"published_at": map[string]any{
					"type": "date",
				},
				"score": map[string]any{
					"type": "float",
				},
				"visible": map[string]any{
					"type": "boolean",
				},
			},
		},
	}
}

func analysisSettings(analyzer string) map[string]any {
	switch analyzer {
	case AnalyzerIK:
		return map[string]any{
			"analyzer": map[string]any{
				"noema_mixed_text": map[string]any{
					"type":      "custom",
					"tokenizer": "ik_max_word",
					"filter":    []string{"lowercase"},
				},
			},
		}
	default:
		return map[string]any{
			"tokenizer": map[string]any{
				"noema_ngram_tokenizer": map[string]any{
					"type":        "ngram",
					"min_gram":    2,
					"max_gram":    3,
					"token_chars": []string{"letter", "digit"},
				},
			},
			"analyzer": map[string]any{
				"noema_mixed_text": map[string]any{
					"type":      "custom",
					"tokenizer": "noema_ngram_tokenizer",
					"filter":    []string{"lowercase"},
				},
			},
		}
	}
}
