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

func TestAllIndexSpecsCoverNativeSearchDocumentFamilies(t *testing.T) {
	family := search.IndexFamily{Prefix: "noema", Version: "v1"}

	specs := elastic.AllIndexSpecs(family, elastic.AnalyzerNGram)

	want := map[string]struct {
		index string
		alias string
	}{
		search.DocumentFamilyArticles: {index: "noema-articles-v1", alias: "noema-articles-read"},
		search.DocumentFamilyComments: {index: "noema-comments-v1", alias: "noema-comments-read"},
		search.DocumentFamilyUsers:    {index: "noema-users-v1", alias: "noema-users-read"},
		search.DocumentFamilyTags:     {index: "noema-tags-v1", alias: "noema-tags-read"},
	}

	if len(specs) != len(want) {
		t.Fatalf("got %d specs, want %d", len(specs), len(want))
	}
	for _, spec := range specs {
		entry, ok := want[spec.DocumentFamily]
		if !ok {
			t.Fatalf("unexpected document family %q", spec.DocumentFamily)
		}
		if spec.IndexName != entry.index || spec.ReadAlias != entry.alias {
			t.Fatalf("%s index/alias = %q/%q, want %q/%q", spec.DocumentFamily, spec.IndexName, spec.ReadAlias, entry.index, entry.alias)
		}
		if _, err := json.Marshal(spec.Mapping); err != nil {
			t.Fatalf("%s mapping must be JSON serializable: %v", spec.DocumentFamily, err)
		}
		delete(want, spec.DocumentFamily)
	}
	if len(want) != 0 {
		t.Fatalf("missing specs for families: %#v", want)
	}
}

func TestCommentUserAndTagIndexSpecsExposeRequiredFields(t *testing.T) {
	family := search.IndexFamily{Prefix: "noema", Version: "v1"}

	cases := []struct {
		name   string
		spec   elastic.IndexSpec
		fields []string
	}{
		{
			name:   "comments",
			spec:   elastic.CommentIndexSpec(family, elastic.AnalyzerNGram),
			fields: []string{"id", "article_id", "body", "author_id", "published", "created_at", "visible"},
		},
		{
			name:   "users",
			spec:   elastic.UserIndexSpec(family, elastic.AnalyzerNGram),
			fields: []string{"id", "username", "name", "summary", "joined_at", "active"},
		},
		{
			name:   "tags",
			spec:   elastic.TagIndexSpec(family, elastic.AnalyzerNGram),
			fields: []string{"id", "name", "hotness_score", "supported", "created_at"},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			props := tc.spec.Mapping["mappings"].(map[string]any)["properties"].(map[string]any)
			for _, field := range tc.fields {
				if _, ok := props[field]; !ok {
					t.Fatalf("expected %s field %q in mapping", tc.name, field)
				}
			}
		})
	}
}

func TestBuildManifestCreatesStableReviewableIndexManifest(t *testing.T) {
	family := search.IndexFamily{Prefix: "noema", Version: "v1"}

	manifest := elastic.BuildManifest(family, elastic.AnalyzerNGram)

	if manifest.SchemaVersion != "noema.search.index-manifest/v1" {
		t.Fatalf("SchemaVersion = %q", manifest.SchemaVersion)
	}
	if manifest.Prefix != "noema" || manifest.Version != "v1" || manifest.Analyzer != elastic.AnalyzerNGram {
		t.Fatalf("manifest identity = prefix %q version %q analyzer %q", manifest.Prefix, manifest.Version, manifest.Analyzer)
	}
	if len(manifest.Indexes) != 4 {
		t.Fatalf("manifest contains %d indexes, want 4", len(manifest.Indexes))
	}
	for i, wantFamily := range []string{search.DocumentFamilyArticles, search.DocumentFamilyComments, search.DocumentFamilyUsers, search.DocumentFamilyTags} {
		if manifest.Indexes[i].DocumentFamily != wantFamily {
			t.Fatalf("manifest.Indexes[%d].DocumentFamily = %q, want %q", i, manifest.Indexes[i].DocumentFamily, wantFamily)
		}
		if manifest.Indexes[i].Mapping == nil {
			t.Fatalf("manifest.Indexes[%d].Mapping is nil", i)
		}
	}
}

func TestManifestJSONIsDeterministicAndReviewable(t *testing.T) {
	family := search.IndexFamily{Prefix: "noema", Version: "v1"}

	first, err := elastic.ManifestJSON(family, elastic.AnalyzerNGram)
	if err != nil {
		t.Fatalf("ManifestJSON returned error: %v", err)
	}
	second, err := elastic.ManifestJSON(family, elastic.AnalyzerNGram)
	if err != nil {
		t.Fatalf("ManifestJSON returned error on second call: %v", err)
	}
	if string(first) != string(second) {
		t.Fatalf("ManifestJSON must be deterministic between calls")
	}

	var decoded struct {
		SchemaVersion string `json:"schema_version"`
		Indexes       []struct {
			DocumentFamily string         `json:"document_family"`
			IndexName      string         `json:"index_name"`
			ReadAlias      string         `json:"read_alias"`
			Mapping        map[string]any `json:"mapping"`
		} `json:"indexes"`
	}
	if err := json.Unmarshal(first, &decoded); err != nil {
		t.Fatalf("ManifestJSON must be valid JSON: %v\n%s", err, string(first))
	}
	if decoded.SchemaVersion != "noema.search.index-manifest/v1" || len(decoded.Indexes) != 4 {
		t.Fatalf("decoded manifest = schema %q indexes %d", decoded.SchemaVersion, len(decoded.Indexes))
	}
	if decoded.Indexes[0].IndexName != "noema-articles-v1" || decoded.Indexes[0].ReadAlias != "noema-articles-read" {
		t.Fatalf("first index identity = %q/%q", decoded.Indexes[0].IndexName, decoded.Indexes[0].ReadAlias)
	}
}

func TestValidateManifestAcceptsGeneratedManifest(t *testing.T) {
	manifest := elastic.BuildManifest(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram)

	if err := elastic.ValidateManifest(manifest); err != nil {
		t.Fatalf("ValidateManifest returned error for generated manifest: %v", err)
	}
}

func TestValidateManifestRejectsDuplicateIndexIdentity(t *testing.T) {
	manifest := elastic.BuildManifest(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram)
	manifest.Indexes[1].IndexName = manifest.Indexes[0].IndexName

	err := elastic.ValidateManifest(manifest)
	if err == nil {
		t.Fatal("expected duplicate index name validation error")
	}
	if got := err.Error(); got != "duplicate index_name noema-articles-v1" {
		t.Fatalf("error = %q", got)
	}
}

func TestValidateManifestRejectsNonStrictMapping(t *testing.T) {
	manifest := elastic.BuildManifest(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram)
	manifest.Indexes[0].Mapping["mappings"].(map[string]any)["dynamic"] = "true"

	err := elastic.ValidateManifest(manifest)
	if err == nil {
		t.Fatal("expected non-strict mapping validation error")
	}
	if got := err.Error(); got != "articles mapping dynamic must be strict" {
		t.Fatalf("error = %q", got)
	}
}

func TestIndexSpecIncludesWriteAliasForBootstrapAndReindexFlows(t *testing.T) {
	family := search.IndexFamily{Prefix: "noema", Version: "v1"}

	spec := elastic.ArticleIndexSpec(family, elastic.AnalyzerNGram)

	if spec.WriteAlias != "noema-articles-write" {
		t.Fatalf("WriteAlias = %q, want noema-articles-write", spec.WriteAlias)
	}
}

func TestBuildBootstrapPlanIsLocalReviewOnlyAndOrdered(t *testing.T) {
	family := search.IndexFamily{Prefix: "noema", Version: "v1"}

	plan := elastic.BuildBootstrapPlan(family, elastic.AnalyzerNGram)

	if plan.SchemaVersion != "noema.search.bootstrap-plan/v1" {
		t.Fatalf("SchemaVersion = %q", plan.SchemaVersion)
	}
	if plan.Safety != "review-only" {
		t.Fatalf("Safety = %q, want review-only", plan.Safety)
	}
	if len(plan.Steps) != 12 {
		t.Fatalf("plan contains %d steps, want 12", len(plan.Steps))
	}
	first := plan.Steps[0]
	if first.Action != "create_index" || first.DocumentFamily != search.DocumentFamilyArticles || first.IndexName != "noema-articles-v1" {
		t.Fatalf("first step = %#v", first)
	}
	last := plan.Steps[len(plan.Steps)-1]
	if last.Action != "point_write_alias" || last.DocumentFamily != search.DocumentFamilyTags || last.Alias != "noema-tags-write" || last.IndexName != "noema-tags-v1" {
		t.Fatalf("last step = %#v", last)
	}
}

func TestBootstrapPlanJSONValidatesManifestBeforeRendering(t *testing.T) {
	family := search.IndexFamily{Prefix: "noema", Version: "v1"}

	payload, err := elastic.BootstrapPlanJSON(family, elastic.AnalyzerNGram)
	if err != nil {
		t.Fatalf("BootstrapPlanJSON returned error: %v", err)
	}

	var decoded struct {
		SchemaVersion string `json:"schema_version"`
		Safety        string `json:"safety"`
		Steps         []struct {
			Action         string `json:"action"`
			DocumentFamily string `json:"document_family"`
			IndexName      string `json:"index_name"`
			Alias          string `json:"alias,omitempty"`
		} `json:"steps"`
	}
	if err := json.Unmarshal(payload, &decoded); err != nil {
		t.Fatalf("BootstrapPlanJSON must be valid JSON: %v\n%s", err, string(payload))
	}
	if decoded.SchemaVersion != "noema.search.bootstrap-plan/v1" || decoded.Safety != "review-only" || len(decoded.Steps) != 12 {
		t.Fatalf("decoded plan = schema %q safety %q steps %d", decoded.SchemaVersion, decoded.Safety, len(decoded.Steps))
	}
}
