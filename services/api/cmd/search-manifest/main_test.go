package main

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"
)

func TestRunWritesSearchIndexManifestJSON(t *testing.T) {
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
		Prefix        string `json:"prefix"`
		Version       string `json:"version"`
		Analyzer      string `json:"analyzer"`
		Indexes       []struct {
			DocumentFamily string `json:"document_family"`
			IndexName      string `json:"index_name"`
			ReadAlias      string `json:"read_alias"`
		} `json:"indexes"`
	}
	if err := json.Unmarshal(stdout.Bytes(), &decoded); err != nil {
		t.Fatalf("stdout must be JSON: %v\n%s", err, stdout.String())
	}
	if decoded.SchemaVersion != "noema.search.index-manifest/v1" || decoded.Prefix != "noema" || decoded.Version != "v1" || decoded.Analyzer != "ngram" {
		t.Fatalf("decoded manifest identity = %#v", decoded)
	}
	if len(decoded.Indexes) != 4 || decoded.Indexes[0].DocumentFamily != "articles" || decoded.Indexes[3].DocumentFamily != "tags" {
		t.Fatalf("unexpected index family coverage: %#v", decoded.Indexes)
	}
	if !strings.HasSuffix(stdout.String(), "\n") {
		t.Fatalf("manifest output should end with newline for shell use")
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
