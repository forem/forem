package identity_test

import (
	"context"
	"testing"

	"github.com/agentwego/noema/services/api/internal/identity"
)

func TestLocalKratosAdapterBuildsReviewOnlyOperationPlans(t *testing.T) {
	adapter := identity.NewLocalKratosAdapter()
	ctx := context.Background()

	identityPlan, err := adapter.PreviewIdentityImportOperation(ctx, identity.KratosIdentityImport{
		SchemaID: identity.DefaultKratosIdentitySchemaID,
		Traits: identity.KratosTraits{
			Email:    "alice@example.com",
			Username: "alice",
			Name:     "Alice Example",
		},
		MetadataPublic: map[string]string{"profile_image": "https://example.com/avatar.png"},
		MetadataAdmin: map[string]string{
			"legacy_forem_user_id":   "42",
			"legacy_identity_github": "github:alice-gh",
		},
	})
	if err != nil {
		t.Fatalf("PreviewIdentityImportOperation returned error: %v", err)
	}
	if identityPlan.SchemaVersion != identity.KratosOperationPlanSchemaVersion {
		t.Fatalf("schema_version = %q", identityPlan.SchemaVersion)
	}
	if identityPlan.Surface != identity.KratosSurfaceAdmin || identityPlan.Method != "POST" || identityPlan.Path != "/admin/identities" {
		t.Fatalf("unexpected identity operation plan: %+v", identityPlan)
	}
	if identityPlan.Execution != identity.KratosOperationExecutionReviewOnly || !identityPlan.SensitiveFieldsExcluded {
		t.Fatalf("operation plan is not review-only/sensitive-excluding: %+v", identityPlan)
	}
	if identityPlan.Body["schema_id"] != identity.DefaultKratosIdentitySchemaID {
		t.Fatalf("identity operation body missing schema_id: %+v", identityPlan.Body)
	}
	if _, ok := identityPlan.Body["credentials"]; ok {
		t.Fatalf("identity operation plan must not include credentials: %+v", identityPlan.Body)
	}
	traits, ok := identityPlan.Body["traits"].(map[string]string)
	if !ok || traits["username"] != "alice" || traits["email"] != "alice@example.com" {
		t.Fatalf("identity operation traits not preserved: %#v", identityPlan.Body["traits"])
	}

	whoamiPlan, err := adapter.PreviewSessionWhoAmIOperation(ctx)
	if err != nil {
		t.Fatalf("PreviewSessionWhoAmIOperation returned error: %v", err)
	}
	if whoamiPlan.Surface != identity.KratosSurfacePublic || whoamiPlan.Method != "GET" || whoamiPlan.Path != "/sessions/whoami" {
		t.Fatalf("unexpected whoami operation plan: %+v", whoamiPlan)
	}
	if len(whoamiPlan.Body) != 0 {
		t.Fatalf("whoami operation plan must not contain request body: %+v", whoamiPlan.Body)
	}

	flowPlan, err := adapter.PreviewSelfServiceFlowOperation(ctx, identity.KratosFlowSettings, "https://noema.local/settings")
	if err != nil {
		t.Fatalf("PreviewSelfServiceFlowOperation returned error: %v", err)
	}
	if flowPlan.Surface != identity.KratosSurfacePublic || flowPlan.Method != "GET" || flowPlan.Path != "/self-service/settings/browser" {
		t.Fatalf("unexpected self-service flow operation plan: %+v", flowPlan)
	}
	if flowPlan.FlowKind != identity.KratosFlowSettings || flowPlan.Query["return_to"] != "https://noema.local/settings" {
		t.Fatalf("flow operation did not preserve kind/return_to: %+v", flowPlan)
	}
}

func TestLocalKratosAdapterRejectsSensitiveOperationPlanInput(t *testing.T) {
	adapter := identity.NewLocalKratosAdapter()
	_, err := adapter.PreviewIdentityImportOperation(context.Background(), identity.KratosIdentityImport{
		SchemaID: identity.DefaultKratosIdentitySchemaID,
		Traits:   identity.KratosTraits{Username: "alice"},
		MetadataAdmin: map[string]string{
			"legacy_forem_user_id": "42",
			"oauth_secret":         "do-not-import",
		},
	})
	if err == nil {
		t.Fatal("expected sensitive operation-plan input to be rejected")
	}
}
