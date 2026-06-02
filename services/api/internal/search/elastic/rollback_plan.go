package elastic

import (
	"encoding/json"

	"github.com/agentwego/noema/services/api/internal/search"
)

const RollbackPlanSchemaVersion = "noema.search.rollback-plan/v1"

type RollbackPlan struct {
	SchemaVersion string              `json:"schema_version"`
	Safety        string              `json:"safety"`
	Manifest      IndexManifest       `json:"manifest"`
	Steps         []BootstrapPlanStep `json:"steps"`
}

func BuildRollbackPlan(family search.IndexFamily, analyzer string) RollbackPlan {
	manifest := BuildManifest(family, analyzer)
	steps := make([]BootstrapPlanStep, 0, len(manifest.Indexes)*3)
	for i := len(manifest.Indexes) - 1; i >= 0; i-- {
		spec := manifest.Indexes[i]
		steps = append(steps, BootstrapPlanStep{
			Action:         "remove_write_alias",
			DocumentFamily: spec.DocumentFamily,
			IndexName:      spec.IndexName,
			Alias:          spec.WriteAlias,
		})
		steps = append(steps, BootstrapPlanStep{
			Action:         "remove_read_alias",
			DocumentFamily: spec.DocumentFamily,
			IndexName:      spec.IndexName,
			Alias:          spec.ReadAlias,
		})
		steps = append(steps, BootstrapPlanStep{
			Action:         "delete_index",
			DocumentFamily: spec.DocumentFamily,
			IndexName:      spec.IndexName,
		})
	}
	return RollbackPlan{
		SchemaVersion: RollbackPlanSchemaVersion,
		Safety:        "review-only",
		Manifest:      manifest,
		Steps:         steps,
	}
}

func RollbackPlanJSON(family search.IndexFamily, analyzer string) ([]byte, error) {
	plan := BuildRollbackPlan(family, analyzer)
	if err := ValidateManifest(plan.Manifest); err != nil {
		return nil, err
	}
	return json.MarshalIndent(plan, "", "  ")
}
