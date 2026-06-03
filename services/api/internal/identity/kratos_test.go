package identity_test

import (
	"encoding/json"
	"os"
	"testing"
	"time"

	"github.com/agentwego/noema/services/api/internal/identity"
)

func TestKratosIdentityImportFromFixture(t *testing.T) {
	payload := readKratosFixture(t)

	if payload.Identity.SchemaID != "noema-user-v1" {
		t.Fatalf("unexpected schema id: %+v", payload.Identity)
	}
	if payload.Identity.Traits.Username != "alice" || payload.Identity.Traits.Name != "Alice Example" {
		t.Fatalf("unexpected traits: %+v", payload.Identity.Traits)
	}
	if payload.Identity.Traits.Email != "alice@example.com" {
		t.Fatalf("expected email trait to be preserved, got %q", payload.Identity.Traits.Email)
	}
	if payload.Identity.MetadataAdmin["legacy_forem_user_id"] != "42" {
		t.Fatalf("expected legacy user id in admin metadata, got %+v", payload.Identity.MetadataAdmin)
	}
	if payload.Identity.MetadataAdmin["legacy_identity_github"] != "github:alice-gh" {
		t.Fatalf("expected provider subject in admin metadata, got %+v", payload.Identity.MetadataAdmin)
	}
	if payload.Identity.MetadataPublic["profile_image"] != "https://example.com/avatar.png" {
		t.Fatalf("expected public profile metadata, got %+v", payload.Identity.MetadataPublic)
	}
}

func TestKratosSessionBoundaryFromFixture(t *testing.T) {
	payload := readKratosFixture(t)

	if payload.Session.ID != "kratos-session-preview" || !payload.Session.Active {
		t.Fatalf("unexpected session boundary: %+v", payload.Session)
	}
	if payload.Session.IdentityID != "kratos-identity-preview" {
		t.Fatalf("expected session identity reference, got %+v", payload.Session)
	}
	if got := payload.Session.AuthenticatedAt.Format(time.RFC3339); got != "2026-06-03T01:31:00Z" {
		t.Fatalf("unexpected authenticated_at: %s", got)
	}
}

func TestSelfServiceFlowKindsAreOryNamed(t *testing.T) {
	got := []identity.KratosSelfServiceFlowKind{
		identity.KratosFlowLogin,
		identity.KratosFlowRegistration,
		identity.KratosFlowSettings,
		identity.KratosFlowRecovery,
		identity.KratosFlowVerification,
	}
	want := []string{"login", "registration", "settings", "recovery", "verification"}
	for i, flow := range got {
		if string(flow) != want[i] {
			t.Fatalf("flow[%d] = %q, want %q", i, flow, want[i])
		}
	}
}

type kratosFixturePayload struct {
	Identity identity.KratosIdentityImport `json:"identity"`
	Session  identity.KratosSession        `json:"session"`
}

func readKratosFixture(t *testing.T) kratosFixturePayload {
	t.Helper()
	bytes, err := os.ReadFile("testdata/kratos_identity_session.json")
	if err != nil {
		t.Fatalf("read fixture: %v", err)
	}
	var payload kratosFixturePayload
	if err := json.Unmarshal(bytes, &payload); err != nil {
		t.Fatalf("decode fixture: %v", err)
	}
	return payload
}
