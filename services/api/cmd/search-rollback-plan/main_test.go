package main

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"
)

func TestRunWritesRollbackPlanJSON(t *testing.T) {
	var stdout bytes.Buffer
	var stderr bytes.Buffer

	err := run([]string{"-prefix", "noema", "-version", "v1", "-analyzer", "ngram"}, &stdout, &stderr)
	if err != nil {
		t.Fatalf("run returned error: %v stderr=%s", err, stderr.String())
	}

	var decoded struct {
		SchemaVersion string `json:"schema_version"`
		Safety        string `json:"safety"`
		Manifest      struct {
			Indexes []struct {
				DocumentFamily string `json:"document_family"`
			} `json:"indexes"`
		} `json:"manifest"`
		Steps []struct {
			Action string `json:"action"`
			Alias  string `json:"alias"`
		} `json:"steps"`
	}
	if err := json.Unmarshal(stdout.Bytes(), &decoded); err != nil {
		t.Fatalf("stdout is not rollback JSON: %v\n%s", err, stdout.String())
	}
	if decoded.SchemaVersion != "noema.search.rollback-plan/v1" || decoded.Safety != "review-only" {
		t.Fatalf("schema/safety = %q/%q", decoded.SchemaVersion, decoded.Safety)
	}
	if len(decoded.Manifest.Indexes) != 4 || len(decoded.Steps) != 12 {
		t.Fatalf("manifest indexes/steps = %d/%d", len(decoded.Manifest.Indexes), len(decoded.Steps))
	}
	if decoded.Steps[0].Action != "remove_write_alias" || decoded.Steps[len(decoded.Steps)-1].Action != "delete_index" {
		t.Fatalf("unexpected rollback edge steps: first=%q last=%q", decoded.Steps[0].Action, decoded.Steps[len(decoded.Steps)-1].Action)
	}
}

func TestRunRejectsUnknownRollbackAnalyzer(t *testing.T) {
	var stdout bytes.Buffer
	var stderr bytes.Buffer

	err := run([]string{"-analyzer", "unknown"}, &stdout, &stderr)
	if err == nil {
		t.Fatal("expected analyzer validation error")
	}
	if !strings.Contains(err.Error(), "unknown analyzer") {
		t.Fatalf("error = %q", err.Error())
	}
}
