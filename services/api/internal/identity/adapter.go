package identity

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"strings"
	"time"
)

var (
	ErrMissingKratosSchemaID = errors.New("kratos identity schema_id is required")
	ErrMissingKratosUsername = errors.New("kratos identity username trait is required")
	ErrSensitiveMetadata     = errors.New("kratos identity preview contains sensitive metadata")
)

// KratosTargetAdapter is the local adapter spec for future Ory Kratos Admin and
// Public API wiring. M0-T34 keeps it as a pure preview interface: no HTTP client,
// no cookies, no tokens, and no self-service flow execution.
type KratosTargetAdapter interface {
	PreviewIdentityImport(ctx context.Context, input KratosIdentityImport) (KratosIdentityImport, error)
	PreviewSession(ctx context.Context, identityID string) (KratosSession, error)
	PreviewSelfServiceFlows(ctx context.Context, returnTo string) ([]KratosSelfServiceFlow, error)
	PreviewIdentityImportOperation(ctx context.Context, input KratosIdentityImport) (KratosOperationPlan, error)
	PreviewSessionWhoAmIOperation(ctx context.Context) (KratosOperationPlan, error)
	PreviewSelfServiceFlowOperation(ctx context.Context, kind KratosSelfServiceFlowKind, returnTo string) (KratosOperationPlan, error)
}

type LocalKratosAdapter struct{}

func NewLocalKratosAdapter() LocalKratosAdapter {
	return LocalKratosAdapter{}
}

func (LocalKratosAdapter) PreviewIdentityImport(_ context.Context, input KratosIdentityImport) (KratosIdentityImport, error) {
	if strings.TrimSpace(input.SchemaID) == "" {
		return KratosIdentityImport{}, ErrMissingKratosSchemaID
	}
	if strings.TrimSpace(input.Traits.Username) == "" {
		return KratosIdentityImport{}, ErrMissingKratosUsername
	}
	if containsSensitiveMetadata(input.MetadataPublic) || containsSensitiveMetadata(input.MetadataAdmin) {
		return KratosIdentityImport{}, ErrSensitiveMetadata
	}

	preview := input
	preview.Traits.Email = strings.TrimSpace(preview.Traits.Email)
	preview.Traits.Username = strings.TrimSpace(preview.Traits.Username)
	preview.Traits.Name = strings.TrimSpace(preview.Traits.Name)
	if preview.State == "" {
		preview.State = "active"
	}
	if preview.ID == "" {
		preview.ID = fmt.Sprintf("kratos-preview-identity-%s", previewIdentitySuffix(preview))
	}
	return preview, nil
}

func (LocalKratosAdapter) PreviewSession(_ context.Context, identityID string) (KratosSession, error) {
	identityID = strings.TrimSpace(identityID)
	if identityID == "" {
		return KratosSession{}, errors.New("kratos identity id is required")
	}
	suffix := strings.TrimPrefix(identityID, "kratos-preview-identity-")
	return KratosSession{
		ID:              fmt.Sprintf("kratos-preview-session-%s", suffix),
		Active:          true,
		IdentityID:      identityID,
		AuthenticatedAt: time.Time{},
		IssuedAt:        time.Time{},
		ExpiresAt:       time.Time{},
	}, nil
}

func (LocalKratosAdapter) PreviewSelfServiceFlows(_ context.Context, returnTo string) ([]KratosSelfServiceFlow, error) {
	returnTo = strings.TrimSpace(returnTo)
	kinds := []KratosSelfServiceFlowKind{
		KratosFlowLogin,
		KratosFlowRegistration,
		KratosFlowSettings,
		KratosFlowRecovery,
		KratosFlowVerification,
	}
	flows := make([]KratosSelfServiceFlow, 0, len(kinds))
	for _, kind := range kinds {
		path, ok := selfServiceFlowBrowserPath(kind)
		if !ok {
			return nil, fmt.Errorf("unsupported Kratos self-service flow kind: %s", kind)
		}
		flows = append(flows, KratosSelfServiceFlow{
			ID:         fmt.Sprintf("kratos-preview-flow-%s", kind),
			Kind:       kind,
			RequestURL: selfServiceFlowRequestURL(path, returnTo),
			ReturnTo:   returnTo,
		})
	}
	return flows, nil
}

func selfServiceFlowRequestURL(path string, returnTo string) string {
	returnTo = strings.TrimSpace(returnTo)
	if returnTo == "" {
		return path
	}
	values := url.Values{}
	values.Set("return_to", returnTo)
	return fmt.Sprintf("%s?%s", path, values.Encode())
}

func previewIdentitySuffix(input KratosIdentityImport) string {
	if legacyID := strings.TrimSpace(input.MetadataAdmin["legacy_forem_user_id"]); legacyID != "" {
		return legacyID
	}
	return strings.ToLower(strings.ReplaceAll(input.Traits.Username, " ", "-"))
}

func containsSensitiveMetadata(metadata map[string]string) bool {
	for key := range metadata {
		lower := strings.ToLower(key)
		if strings.Contains(lower, "token") || strings.Contains(lower, "secret") || strings.Contains(lower, "password") || strings.Contains(lower, "cookie") || strings.Contains(lower, "csrf") || strings.Contains(lower, "auth_dump") || strings.Contains(lower, "raw_auth") {
			return true
		}
	}
	return false
}
