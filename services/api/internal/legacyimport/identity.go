package legacyimport

import (
	"fmt"
	"strings"

	noemaidentity "github.com/agentwego/noema/services/api/internal/identity"
)

// ForemExternalIdentity is the minimal legacy OmniAuth identity binding shape
// needed to preserve provider subjects as Kratos admin metadata. Tokens, secrets,
// and auth dumps intentionally stay out of the native import boundary.
type ForemExternalIdentity struct {
	Provider string `json:"provider"`
	UID      string `json:"uid"`
}

// ForemUserIdentity combines the clean Forem user import shape with legacy
// external identity hints. It maps toward Ory Kratos identity semantics without
// creating a durable custom auth system.
type ForemUserIdentity struct {
	User               ForemUser               `json:"user"`
	Email              string                  `json:"email"`
	KratosReturnTo     string                  `json:"kratos_return_to,omitempty"`
	ExternalIdentities []ForemExternalIdentity `json:"external_identities"`
}

// UserIdentityBoundary is the M0-T31 bridge between legacy Forem user inventory
// and the future Ory Kratos identity/session integration boundary.
type UserIdentityBoundary struct {
	User           UserDTO                            `json:"user"`
	KratosIdentity noemaidentity.KratosIdentityImport `json:"kratos_identity"`
}

func MapForemUserIdentity(input ForemUserIdentity) (UserIdentityBoundary, error) {
	user, err := MapForemUser(input.User)
	if err != nil {
		return UserIdentityBoundary{}, err
	}

	publicMetadata := map[string]string{}
	if input.User.ProfileImage != "" {
		publicMetadata["profile_image"] = input.User.ProfileImage
	}
	adminMetadata := map[string]string{
		"legacy_forem_user_id": user.ID,
	}
	for _, external := range input.ExternalIdentities {
		provider := strings.TrimSpace(external.Provider)
		uid := strings.TrimSpace(external.UID)
		if provider == "" || uid == "" {
			continue
		}
		adminMetadata[fmt.Sprintf("legacy_identity_%s", provider)] = fmt.Sprintf("%s:%s", provider, uid)
	}

	return UserIdentityBoundary{
		User: user,
		KratosIdentity: noemaidentity.KratosIdentityImport{
			SchemaID: noemaidentity.DefaultKratosIdentitySchemaID,
			State:    "active",
			Traits: noemaidentity.KratosTraits{
				Email:    strings.TrimSpace(input.Email),
				Username: user.Username,
				Name:     user.DisplayName,
			},
			MetadataPublic: publicMetadata,
			MetadataAdmin:  adminMetadata,
			CreatedAt:      user.CreatedAt,
			UpdatedAt:      user.UpdatedAt,
		},
	}, nil
}
