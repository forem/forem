package elastic

import (
	"encoding/json"
	"errors"
	"fmt"

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
	manifest := BuildManifest(family, analyzer)
	if err := ValidateManifest(manifest); err != nil {
		return nil, err
	}
	return json.MarshalIndent(manifest, "", "  ")
}

func ValidateManifest(manifest IndexManifest) error {
	if manifest.SchemaVersion != ManifestSchemaVersion {
		return fmt.Errorf("schema_version must be %s", ManifestSchemaVersion)
	}
	if manifest.Prefix == "" {
		return errors.New("prefix must not be empty")
	}
	if manifest.Version == "" {
		return errors.New("version must not be empty")
	}
	if manifest.Analyzer != AnalyzerNGram && manifest.Analyzer != AnalyzerIK {
		return fmt.Errorf("unknown analyzer %q", manifest.Analyzer)
	}
	if len(manifest.Indexes) == 0 {
		return errors.New("indexes must not be empty")
	}

	families := map[string]struct{}{}
	indexes := map[string]struct{}{}
	aliases := map[string]struct{}{}
	for _, spec := range manifest.Indexes {
		if spec.DocumentFamily == "" {
			return errors.New("document_family must not be empty")
		}
		if _, ok := families[spec.DocumentFamily]; ok {
			return fmt.Errorf("duplicate document_family %s", spec.DocumentFamily)
		}
		families[spec.DocumentFamily] = struct{}{}

		if spec.IndexName == "" {
			return fmt.Errorf("%s index_name must not be empty", spec.DocumentFamily)
		}
		if _, ok := indexes[spec.IndexName]; ok {
			return fmt.Errorf("duplicate index_name %s", spec.IndexName)
		}
		indexes[spec.IndexName] = struct{}{}

		if spec.ReadAlias == "" {
			return fmt.Errorf("%s read_alias must not be empty", spec.DocumentFamily)
		}
		if _, ok := aliases[spec.ReadAlias]; ok {
			return fmt.Errorf("duplicate read_alias %s", spec.ReadAlias)
		}
		aliases[spec.ReadAlias] = struct{}{}

		if err := validateMapping(spec); err != nil {
			return err
		}
	}
	return nil
}

func validateMapping(spec IndexSpec) error {
	if _, err := json.Marshal(spec.Mapping); err != nil {
		return fmt.Errorf("%s mapping must be JSON serializable: %w", spec.DocumentFamily, err)
	}
	mappings, ok := spec.Mapping["mappings"].(map[string]any)
	if !ok {
		return fmt.Errorf("%s mapping missing mappings object", spec.DocumentFamily)
	}
	if mappings["dynamic"] != "strict" {
		return fmt.Errorf("%s mapping dynamic must be strict", spec.DocumentFamily)
	}
	properties, ok := mappings["properties"].(map[string]any)
	if !ok || len(properties) == 0 {
		return fmt.Errorf("%s mapping properties must not be empty", spec.DocumentFamily)
	}
	return nil
}
