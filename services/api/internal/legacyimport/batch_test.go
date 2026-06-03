package legacyimport_test

import (
	"context"
	"encoding/json"
	"os"
	"strings"
	"testing"

	"github.com/agentwego/noema/services/api/internal/legacyimport"
)

func TestPreviewServiceBuildsBatchWithPerItemErrorsAndOperationPlans(t *testing.T) {
	request := readPreviewBatchFixture(t)

	batch, err := legacyimport.NewPreviewService(legacyimport.PreviewServiceOptions{}).PreviewForemArticleUserIdentityBatch(context.Background(), request)
	if err != nil {
		t.Fatalf("PreviewForemArticleUserIdentityBatch returned error: %v", err)
	}

	if batch.SchemaVersion != legacyimport.ImportBatchPreviewSchemaVersion {
		t.Fatalf("batch schema_version = %q", batch.SchemaVersion)
	}
	if batch.Total != 2 || batch.Succeeded != 1 || batch.Failed != 1 || len(batch.Items) != 2 {
		t.Fatalf("unexpected batch counts/items: %+v", batch)
	}
	if batch.SideEffects != legacyimport.ImportPreviewSideEffects {
		t.Fatalf("batch side_effects = %q", batch.SideEffects)
	}

	first := batch.Items[0]
	if first.Index != 0 || first.Error != "" || first.Preview == nil {
		t.Fatalf("first item should be a successful preview: %+v", first)
	}
	if first.Preview.Bundle.User.ID != "42" || first.Preview.Bundle.Article.ID != "123459" {
		t.Fatalf("first item preview mapped wrong DTOs: %+v", first.Preview.Bundle)
	}
	if first.Preview.Kratos.Identity.ID != "kratos-preview-identity-42" || first.Preview.Kratos.OperationPlans[0].Path != "/admin/identities" {
		t.Fatalf("first item missing Kratos identity operation plan: %+v", first.Preview.Kratos)
	}
	if first.Preview.Kratos.OperationPlans[0].Execution != "review-only" {
		t.Fatalf("Kratos operation plan should be review-only: %+v", first.Preview.Kratos.OperationPlans[0])
	}

	second := batch.Items[1]
	if second.Index != 1 || second.Preview != nil || second.Error == "" {
		t.Fatalf("second item should be a per-item error: %+v", second)
	}
	if !strings.Contains(second.Error, "legacy article slug is required") {
		t.Fatalf("second item error = %q", second.Error)
	}
}

func TestPreviewServiceRejectsEmptyBatch(t *testing.T) {
	_, err := legacyimport.NewPreviewService(legacyimport.PreviewServiceOptions{}).PreviewForemArticleUserIdentityBatch(context.Background(), legacyimport.ImportBatchPreviewRequest{})
	if err == nil {
		t.Fatal("expected empty batch to fail")
	}
}

func readPreviewBatchFixture(t *testing.T) legacyimport.ImportBatchPreviewRequest {
	t.Helper()
	bytes, err := os.ReadFile("testdata/forem_article_user_identity_batch_mixed.json")
	if err != nil {
		t.Fatalf("read batch fixture: %v", err)
	}
	var input legacyimport.ImportBatchPreviewRequest
	if err := json.Unmarshal(bytes, &input); err != nil {
		t.Fatalf("decode batch fixture: %v", err)
	}
	return input
}
