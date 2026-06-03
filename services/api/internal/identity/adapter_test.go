package identity_test

import (
	"context"
	"testing"
	"time"

	"github.com/agentwego/noema/services/api/internal/identity"
)

func TestLocalKratosAdapterPreviewsIdentitySessionAndSelfServiceFlows(t *testing.T) {
	adapter := identity.NewLocalKratosAdapter()
	createdAt := time.Date(2026, 6, 3, 0, 0, 0, 0, time.UTC)
	updatedAt := time.Date(2026, 6, 3, 1, 30, 0, 0, time.UTC)

	preview, err := adapter.PreviewIdentityImport(context.Background(), identity.KratosIdentityImport{
		SchemaID: identity.DefaultKratosIdentitySchemaID,
		State:    "active",
		Traits: identity.KratosTraits{
			Email:    "alice@example.com",
			Username: "alice",
			Name:     "Alice Example",
		},
		MetadataPublic: map[string]string{
			"profile_image": "https://example.com/avatar.png",
		},
		MetadataAdmin: map[string]string{
			"legacy_forem_user_id":   "42",
			"legacy_identity_github": "github:alice-gh",
		},
		CreatedAt: createdAt,
		UpdatedAt: updatedAt,
	})
	if err != nil {
		t.Fatalf("PreviewIdentityImport returned error: %v", err)
	}

	if preview.ID != "kratos-preview-identity-42" {
		t.Fatalf("identity preview id = %q, want kratos-preview-identity-42", preview.ID)
	}
	if preview.Traits.Email != "alice@example.com" || preview.Traits.Username != "alice" {
		t.Fatalf("identity traits were not preserved: %+v", preview.Traits)
	}
	if preview.MetadataAdmin["legacy_identity_github"] != "github:alice-gh" {
		t.Fatalf("provider subject was not preserved as admin metadata: %+v", preview.MetadataAdmin)
	}

	session, err := adapter.PreviewSession(context.Background(), preview.ID)
	if err != nil {
		t.Fatalf("PreviewSession returned error: %v", err)
	}
	if !session.Active || session.IdentityID != preview.ID {
		t.Fatalf("session did not assert identity reference: %+v", session)
	}
	if session.ID != "kratos-preview-session-42" {
		t.Fatalf("session preview id = %q, want kratos-preview-session-42", session.ID)
	}

	flows, err := adapter.PreviewSelfServiceFlows(context.Background(), "https://noema.local/settings")
	if err != nil {
		t.Fatalf("PreviewSelfServiceFlows returned error: %v", err)
	}
	want := []identity.KratosSelfServiceFlowKind{
		identity.KratosFlowLogin,
		identity.KratosFlowRegistration,
		identity.KratosFlowSettings,
		identity.KratosFlowRecovery,
		identity.KratosFlowVerification,
	}
	if len(flows) != len(want) {
		t.Fatalf("flow count = %d, want %d: %+v", len(flows), len(want), flows)
	}
	for i, flow := range flows {
		if flow.Kind != want[i] {
			t.Fatalf("flow[%d] kind = %q, want %q", i, flow.Kind, want[i])
		}
		if flow.ReturnTo != "https://noema.local/settings" {
			t.Fatalf("flow[%d] return_to = %q", i, flow.ReturnTo)
		}
	}
}

func TestLocalKratosAdapterRejectsIdentityPreviewWithSensitiveAdminMetadata(t *testing.T) {
	adapter := identity.NewLocalKratosAdapter()

	_, err := adapter.PreviewIdentityImport(context.Background(), identity.KratosIdentityImport{
		SchemaID: identity.DefaultKratosIdentitySchemaID,
		Traits: identity.KratosTraits{
			Username: "alice",
		},
		MetadataAdmin: map[string]string{
			"legacy_forem_user_id": "42",
			"oauth_token":          "do-not-import",
		},
	})
	if err == nil {
		t.Fatal("expected sensitive admin metadata to be rejected")
	}
}
