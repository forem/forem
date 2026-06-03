package legacyimport_test

import (
	"testing"
	"time"

	"github.com/agentwego/noema/services/api/internal/legacyimport"
)

func TestMapForemUserIdentityToKratosBoundary(t *testing.T) {
	createdAt := time.Date(2026, 6, 3, 0, 0, 0, 0, time.UTC)
	updatedAt := time.Date(2026, 6, 3, 1, 30, 0, 0, time.UTC)

	boundary, err := legacyimport.MapForemUserIdentity(legacyimport.ForemUserIdentity{
		User: legacyimport.ForemUser{
			ID:           42,
			Username:     " alice ",
			Name:         "Alice Example",
			ProfileImage: "https://example.com/avatar.png",
			CreatedAt:    createdAt,
			UpdatedAt:    updatedAt,
		},
		Email: "alice@example.com",
		ExternalIdentities: []legacyimport.ForemExternalIdentity{
			{Provider: "github", UID: "alice-gh"},
		},
	})
	if err != nil {
		t.Fatalf("MapForemUserIdentity returned error: %v", err)
	}

	if boundary.User.ID != "42" || boundary.User.Username != "alice" || boundary.User.DisplayName != "Alice Example" {
		t.Fatalf("unexpected clean user dto: %+v", boundary.User)
	}
	if boundary.KratosIdentity.SchemaID != "noema-user-v1" || boundary.KratosIdentity.State != "active" {
		t.Fatalf("unexpected Kratos identity envelope: %+v", boundary.KratosIdentity)
	}
	if boundary.KratosIdentity.Traits.Email != "alice@example.com" || boundary.KratosIdentity.Traits.Username != "alice" {
		t.Fatalf("unexpected Kratos traits: %+v", boundary.KratosIdentity.Traits)
	}
	if boundary.KratosIdentity.MetadataAdmin["legacy_forem_user_id"] != "42" {
		t.Fatalf("missing legacy user id in admin metadata: %+v", boundary.KratosIdentity.MetadataAdmin)
	}
	if boundary.KratosIdentity.MetadataAdmin["legacy_identity_github"] != "github:alice-gh" {
		t.Fatalf("missing provider subject in admin metadata: %+v", boundary.KratosIdentity.MetadataAdmin)
	}
	if boundary.KratosIdentity.MetadataPublic["profile_image"] != "https://example.com/avatar.png" {
		t.Fatalf("missing public profile metadata: %+v", boundary.KratosIdentity.MetadataPublic)
	}
}
