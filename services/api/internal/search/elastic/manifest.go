package elastic

import (
	"encoding/json"

	"github.com/agentwego/noema/services/api/internal/search"
)

const ManifestSchemaVersion = "noema.search.index-manifest/v1"

type IndexManifest struct {
	SchemaVersion string      `json:"schema_version"`
	Prefix        string      `json:"prefix"`
	Version       string      `json:"version"`
	Analyzer      string      `json:"analyzer"`
	Indexes       []IndexSpec `json:"indexes"`
}

func BuildManifest(family search.IndexFamily, analyzer string) IndexManifest {
	return IndexManifest{
		SchemaVersion: ManifestSchemaVersion,
		Prefix:        family.Prefix,
		Version:       family.Version,
		Analyzer:      analyzer,
		Indexes:       AllIndexSpecs(family, analyzer),
	}
}

func ManifestJSON(family search.IndexFamily, analyzer string) ([]byte, error) {
	return json.MarshalIndent(BuildManifest(family, analyzer), "", "  ")
}
