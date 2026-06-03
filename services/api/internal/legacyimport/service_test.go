package legacyimport_test

import (
	"context"
	"encoding/json"
	"os"
	"testing"

	"github.com/agentwego/noema/services/api/internal/legacyimport"
)

func TestPreviewServiceBuildsLocalImportPlanFromFixture(t *testing.T) {
	input := readPreviewFixture(t)

	preview, err := legacyimport.NewPreviewService(legacyimport.PreviewServiceOptions{}).PreviewForemArticleUserIdentity(context.Background(), input)
	if err != nil {
		t.Fatalf("PreviewForemArticleUserIdentity returned error: %v", err)
	}

	if preview.SchemaVersion != "noema.legacy-import.preview/v1" {
		t.Fatalf("schema_version = %q", preview.SchemaVersion)
	}
	if preview.Bundle.User.ID != "42" || preview.Bundle.Article.ID != "123459" {
		t.Fatalf("unexpected bundle: %+v", preview.Bundle)
	}
	if preview.Persistence.User.ID != preview.Bundle.User.ID || preview.Persistence.Article.AuthorID != "42" {
		t.Fatalf("unexpected persistence projections: %+v", preview.Persistence)
	}
	if preview.Search.User.DocumentFamily() != "users" || preview.Search.Article.DocumentFamily() != "articles" {
		t.Fatalf("unexpected search projections: %+v", preview.Search)
	}
	if preview.Kratos.Identity.ID != "kratos-preview-identity-42" {
		t.Fatalf("unexpected Kratos identity preview: %+v", preview.Kratos.Identity)
	}
	if !preview.Kratos.Session.Active || preview.Kratos.Session.IdentityID != preview.Kratos.Identity.ID {
		t.Fatalf("unexpected Kratos session preview: %+v", preview.Kratos.Session)
	}
	if len(preview.Kratos.SelfServiceFlows) != 5 {
		t.Fatalf("self-service flow count = %d, want 5", len(preview.Kratos.SelfServiceFlows))
	}
	if preview.SideEffects != "none-local-preview-only" {
		t.Fatalf("side_effects = %q", preview.SideEffects)
	}
}

func TestPreviewServiceReturnsValidationErrorWithoutPlan(t *testing.T) {
	_, err := legacyimport.NewPreviewService(legacyimport.PreviewServiceOptions{}).PreviewForemArticleUserIdentity(context.Background(), legacyimport.ForemArticleUserIdentityImport{})
	if err == nil {
		t.Fatal("expected invalid import input to fail")
	}
}

func readPreviewFixture(t *testing.T) legacyimport.ForemArticleUserIdentityImport {
	t.Helper()
	bytes, err := os.ReadFile("testdata/forem_article_user_identity_preview.json")
	if err != nil {
		t.Fatalf("read preview fixture: %v", err)
	}
	var input legacyimport.ForemArticleUserIdentityImport
	if err := json.Unmarshal(bytes, &input); err != nil {
		t.Fatalf("decode preview fixture: %v", err)
	}
	return input
}
