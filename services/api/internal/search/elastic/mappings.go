package elastic

import "github.com/agentwego/noema/services/api/internal/search"

const (
	AnalyzerNGram = "ngram"
	AnalyzerIK    = "ik"
)

type IndexSpec struct {
	DocumentFamily string         `json:"document_family"`
	IndexName      string         `json:"index_name"`
	ReadAlias      string         `json:"read_alias"`
	Mapping        map[string]any `json:"mapping"`
}

func ArticleIndexSpec(family search.IndexFamily, analyzer string) IndexSpec {
	return newIndexSpec(family, search.DocumentFamilyArticles, articleProperties(), analyzer)
}

func CommentIndexSpec(family search.IndexFamily, analyzer string) IndexSpec {
	return newIndexSpec(family, search.DocumentFamilyComments, commentProperties(), analyzer)
}

func UserIndexSpec(family search.IndexFamily, analyzer string) IndexSpec {
	return newIndexSpec(family, search.DocumentFamilyUsers, userProperties(), analyzer)
}

func TagIndexSpec(family search.IndexFamily, analyzer string) IndexSpec {
	return newIndexSpec(family, search.DocumentFamilyTags, tagProperties(), analyzer)
}

func AllIndexSpecs(family search.IndexFamily, analyzer string) []IndexSpec {
	return []IndexSpec{
		ArticleIndexSpec(family, analyzer),
		CommentIndexSpec(family, analyzer),
		UserIndexSpec(family, analyzer),
		TagIndexSpec(family, analyzer),
	}
}

func newIndexSpec(family search.IndexFamily, documentFamily string, properties map[string]any, analyzer string) IndexSpec {
	return IndexSpec{
		DocumentFamily: documentFamily,
		IndexName:      family.VersionedIndex(documentFamily),
		ReadAlias:      family.ReadAlias(documentFamily),
		Mapping:        documentMapping(properties, analyzer),
	}
}

func documentMapping(properties map[string]any, analyzer string) map[string]any {
	return map[string]any{
		"settings": map[string]any{
			"analysis": analysisSettings(analyzer),
		},
		"mappings": map[string]any{
			"dynamic":    "strict",
			"properties": properties,
		},
	}
}

func articleProperties() map[string]any {
	return map[string]any{
		"id":              keywordField(),
		"path":            keywordField(),
		"title":           textFieldWithKeyword(),
		"body":            textField(),
		"tags":            keywordField(),
		"author_id":       keywordField(),
		"author_username": keywordField(),
		"organization_id": keywordField(),
		"language":        keywordField(),
		"published":       booleanField(),
		"published_at":    dateField(),
		"score":           floatField(),
		"visible":         booleanField(),
	}
}

func commentProperties() map[string]any {
	return map[string]any{
		"id":         keywordField(),
		"article_id": keywordField(),
		"body":       textField(),
		"author_id":  keywordField(),
		"published":  booleanField(),
		"created_at": dateField(),
		"visible":    booleanField(),
	}
}

func userProperties() map[string]any {
	return map[string]any{
		"id":        keywordField(),
		"username":  textFieldWithKeyword(),
		"name":      textFieldWithKeyword(),
		"summary":   textField(),
		"joined_at": dateField(),
		"active":    booleanField(),
	}
}

func tagProperties() map[string]any {
	return map[string]any{
		"id":            keywordField(),
		"name":          textFieldWithKeyword(),
		"hotness_score": floatField(),
		"supported":     booleanField(),
		"created_at":    dateField(),
	}
}

func keywordField() map[string]any { return map[string]any{"type": "keyword"} }

func textField() map[string]any {
	return map[string]any{"type": "text", "analyzer": "noema_mixed_text"}
}

func textFieldWithKeyword() map[string]any {
	field := textField()
	field["fields"] = map[string]any{"keyword": map[string]any{"type": "keyword", "ignore_above": 256}}
	return field
}

func booleanField() map[string]any { return map[string]any{"type": "boolean"} }

func dateField() map[string]any { return map[string]any{"type": "date"} }

func floatField() map[string]any { return map[string]any{"type": "float"} }

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
