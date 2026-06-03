package identity

import "time"

const DefaultKratosIdentitySchemaID = "noema-user-v1"

// KratosIdentityImport is the local import/spec shape Noema uses before wiring a
// real Ory Kratos Admin API client. It mirrors Ory naming (identity, traits,
// metadata_public, metadata_admin) while remaining a pure DTO with no network
// behavior.
type KratosIdentityImport struct {
	ID             string            `json:"id,omitempty"`
	SchemaID       string            `json:"schema_id"`
	State          string            `json:"state,omitempty"`
	Traits         KratosTraits      `json:"traits"`
	MetadataPublic map[string]string `json:"metadata_public,omitempty"`
	MetadataAdmin  map[string]string `json:"metadata_admin,omitempty"`
	CreatedAt      time.Time         `json:"created_at,omitempty"`
	UpdatedAt      time.Time         `json:"updated_at,omitempty"`
}

// KratosTraits is the Noema user schema trait subset for the M0 import seam.
// Email remains an identity trait; profile image is public metadata so that auth
// credentials and profile presentation do not collapse into a custom auth model.
type KratosTraits struct {
	Email    string `json:"email,omitempty"`
	Username string `json:"username"`
	Name     string `json:"name,omitempty"`
}

// KratosSession is the local session assertion DTO for future Kratos
// /sessions/whoami integration. It intentionally stores an identity reference,
// not a Devise/Warden session key.
type KratosSession struct {
	ID              string    `json:"id"`
	Active          bool      `json:"active"`
	IdentityID      string    `json:"identity_id"`
	AuthenticatedAt time.Time `json:"authenticated_at,omitempty"`
	IssuedAt        time.Time `json:"issued_at,omitempty"`
	ExpiresAt       time.Time `json:"expires_at,omitempty"`
}

type KratosSelfServiceFlowKind string

const (
	KratosFlowLogin        KratosSelfServiceFlowKind = "login"
	KratosFlowRegistration KratosSelfServiceFlowKind = "registration"
	KratosFlowSettings     KratosSelfServiceFlowKind = "settings"
	KratosFlowRecovery     KratosSelfServiceFlowKind = "recovery"
	KratosFlowVerification KratosSelfServiceFlowKind = "verification"
)

// KratosSelfServiceFlow is a local envelope for future Ory self-service flow
// wiring. M0-T31 only names the boundary; it does not implement a flow runner.
type KratosSelfServiceFlow struct {
	ID         string                    `json:"id"`
	Kind       KratosSelfServiceFlowKind `json:"type"`
	RequestURL string                    `json:"request_url,omitempty"`
	ReturnTo   string                    `json:"return_to,omitempty"`
	IssuedAt   time.Time                 `json:"issued_at,omitempty"`
	ExpiresAt  time.Time                 `json:"expires_at,omitempty"`
}
