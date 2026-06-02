package elastic

import (
	"encoding/json"

	"github.com/agentwego/noema/services/api/internal/search"
)

const BootstrapPlanSchemaVersion = "noema.search.bootstrap-plan/v1"

type BootstrapPlan struct {
	SchemaVersion string              `json:"schema_version"`
	Safety        string              `json:"safety"`
	Manifest      IndexManifest       `json:"manifest"`
	Steps         []BootstrapPlanStep `json:"steps"`
}

type BootstrapPlanStep struct {
	Action         string         `json:"action"`
	DocumentFamily string         `json:"document_family"`
	IndexName      string         `json:"index_name"`
	Alias          string         `json:"alias,omitempty"`
	Mapping        map[string]any `json:"mapping,omitempty"`
}

func BuildBootstrapPlan(family search.IndexFamily, analyzer string) BootstrapPlan {
	manifest := BuildManifest(family, analyzer)
	steps := make([]BootstrapPlanStep, 0, len(manifest.Indexes)*3)
	for _, spec := range manifest.Indexes {
		steps = append(steps, BootstrapPlanStep{
			Action:         "create_index",
			DocumentFamily: spec.DocumentFamily,
			IndexName:      spec.IndexName,
			Mapping:        spec.Mapping,
		})
		steps = append(steps, BootstrapPlanStep{
			Action:         "point_read_alias",
			DocumentFamily: spec.DocumentFamily,
			IndexName:      spec.IndexName,
			Alias:          spec.ReadAlias,
		})
		steps = append(steps, BootstrapPlanStep{
			Action:         "point_write_alias",
			DocumentFamily: spec.DocumentFamily,
			IndexName:      spec.IndexName,
			Alias:          spec.WriteAlias,
		})
	}
	return BootstrapPlan{
		SchemaVersion: BootstrapPlanSchemaVersion,
		Safety:        "review-only",
		Manifest:      manifest,
		Steps:         steps,
	}
}

func BootstrapPlanJSON(family search.IndexFamily, analyzer string) ([]byte, error) {
	plan := BuildBootstrapPlan(family, analyzer)
	if err := ValidateManifest(plan.Manifest); err != nil {
		return nil, err
	}
	return json.MarshalIndent(plan, "", "  ")
}
