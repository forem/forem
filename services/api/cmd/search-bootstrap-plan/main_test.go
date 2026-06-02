package main

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"
)

func TestRunWritesReviewOnlyBootstrapPlanJSON(t *testing.T) {
	var stdout bytes.Buffer
	var stderr bytes.Buffer

	if err := run([]string{"-prefix", "noema", "-version", "v1", "-analyzer", "ngram"}, &stdout, &stderr); err != nil {
		t.Fatalf("run returned error: %v; stderr=%s", err, stderr.String())
	}
	if stderr.Len() != 0 {
		t.Fatalf("expected empty stderr, got %q", stderr.String())
	}

	var decoded struct {
		SchemaVersion string `json:"schema_version"`
		Safety        string `json:"safety"`
		Manifest      struct {
			Indexes []struct {
				DocumentFamily string `json:"document_family"`
				WriteAlias     string `json:"write_alias"`
			} `json:"indexes"`
		} `json:"manifest"`
		Steps []struct {
			Action         string `json:"action"`
			DocumentFamily string `json:"document_family"`
			IndexName      string `json:"index_name"`
			Alias          string `json:"alias,omitempty"`
		} `json:"steps"`
	}
	if err := json.Unmarshal(stdout.Bytes(), &decoded); err != nil {
		t.Fatalf("stdout must be JSON: %v\n%s", err, stdout.String())
	}
	if decoded.SchemaVersion != "noema.search.bootstrap-plan/v1" || decoded.Safety != "review-only" {
		t.Fatalf("decoded plan identity = %#v", decoded)
	}
	if len(decoded.Manifest.Indexes) != 4 || decoded.Manifest.Indexes[0].WriteAlias != "noema-articles-write" {
		t.Fatalf("unexpected manifest aliases: %#v", decoded.Manifest.Indexes)
	}
	if len(decoded.Steps) != 12 || decoded.Steps[len(decoded.Steps)-1].Action != "point_write_alias" || decoded.Steps[len(decoded.Steps)-1].Alias != "noema-tags-write" {
		t.Fatalf("unexpected step coverage: %#v", decoded.Steps)
	}
	if !strings.HasSuffix(stdout.String(), "\n") {
		t.Fatalf("bootstrap plan output should end with newline for shell use")
	}
}

func TestRunRejectsUnknownAnalyzer(t *testing.T) {
	var stdout bytes.Buffer
	var stderr bytes.Buffer

	err := run([]string{"-analyzer", "unknown"}, &stdout, &stderr)
	if err == nil {
		t.Fatal("expected unknown analyzer error")
	}
	if stdout.Len() != 0 {
		t.Fatalf("expected empty stdout on error, got %q", stdout.String())
	}
	if !strings.Contains(err.Error(), "unknown analyzer") {
		t.Fatalf("error = %q", err.Error())
	}
}
