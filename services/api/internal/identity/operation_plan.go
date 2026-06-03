package identity

import (
	"context"
	"fmt"
)

const KratosOperationPlanSchemaVersion = "noema.kratos.operation-plan/v1"
const KratosOperationExecutionReviewOnly = "review-only"

const (
	KratosSurfaceAdmin  = "admin"
	KratosSurfacePublic = "public"
)

type KratosOperationPlan struct {
	SchemaVersion           string                    `json:"schema_version"`
	Surface                 string                    `json:"surface"`
	Method                  string                    `json:"method"`
	Path                    string                    `json:"path"`
	Query                   map[string]string         `json:"query,omitempty"`
	Body                    map[string]any            `json:"body,omitempty"`
	FlowKind                KratosSelfServiceFlowKind `json:"flow_kind,omitempty"`
	Execution               string                    `json:"execution"`
	SensitiveFieldsExcluded bool                      `json:"sensitive_fields_excluded"`
	ExcludedFields          []string                  `json:"excluded_fields"`
	Notes                   string                    `json:"notes"`
}

func (adapter LocalKratosAdapter) PreviewIdentityImportOperation(ctx context.Context, input KratosIdentityImport) (KratosOperationPlan, error) {
	preview, err := adapter.PreviewIdentityImport(ctx, input)
	if err != nil {
		return KratosOperationPlan{}, err
	}

	body := map[string]any{
		"schema_id":       preview.SchemaID,
		"state":           preview.State,
		"traits":          map[string]string{"email": preview.Traits.Email, "username": preview.Traits.Username, "name": preview.Traits.Name},
		"metadata_public": preview.MetadataPublic,
		"metadata_admin":  preview.MetadataAdmin,
	}

	return KratosOperationPlan{
		SchemaVersion:           KratosOperationPlanSchemaVersion,
		Surface:                 KratosSurfaceAdmin,
		Method:                  "POST",
		Path:                    "/admin/identities",
		Body:                    body,
		Execution:               KratosOperationExecutionReviewOnly,
		SensitiveFieldsExcluded: true,
		ExcludedFields:          sensitiveMetadataFields(),
		Notes:                   "local review-only plan for future Ory Kratos Admin API identity import; no HTTP request is executed",
	}, nil
}

func (LocalKratosAdapter) PreviewSessionWhoAmIOperation(_ context.Context) (KratosOperationPlan, error) {
	return KratosOperationPlan{
		SchemaVersion:           KratosOperationPlanSchemaVersion,
		Surface:                 KratosSurfacePublic,
		Method:                  "GET",
		Path:                    "/sessions/whoami",
		Execution:               KratosOperationExecutionReviewOnly,
		SensitiveFieldsExcluded: true,
		ExcludedFields:          sensitiveMetadataFields(),
		Notes:                   "local review-only plan for future Ory Kratos Public API session whoami check; no cookie or bearer token is captured",
	}, nil
}

func (LocalKratosAdapter) PreviewSelfServiceFlowOperation(_ context.Context, kind KratosSelfServiceFlowKind, returnTo string) (KratosOperationPlan, error) {
	path, ok := selfServiceFlowBrowserPath(kind)
	if !ok {
		return KratosOperationPlan{}, fmt.Errorf("unsupported Kratos self-service flow kind: %s", kind)
	}
	query := map[string]string{}
	if returnTo != "" {
		query["return_to"] = returnTo
	}
	return KratosOperationPlan{
		SchemaVersion:           KratosOperationPlanSchemaVersion,
		Surface:                 KratosSurfacePublic,
		Method:                  "GET",
		Path:                    path,
		Query:                   query,
		FlowKind:                kind,
		Execution:               KratosOperationExecutionReviewOnly,
		SensitiveFieldsExcluded: true,
		ExcludedFields:          sensitiveMetadataFields(),
		Notes:                   "local review-only plan for future Ory Kratos self-service browser flow initialization; no flow is executed",
	}, nil
}

func selfServiceFlowBrowserPath(kind KratosSelfServiceFlowKind) (string, bool) {
	switch kind {
	case KratosFlowLogin:
		return "/self-service/login/browser", true
	case KratosFlowRegistration:
		return "/self-service/registration/browser", true
	case KratosFlowSettings:
		return "/self-service/settings/browser", true
	case KratosFlowRecovery:
		return "/self-service/recovery/browser", true
	case KratosFlowVerification:
		return "/self-service/verification/browser", true
	default:
		return "", false
	}
}

func sensitiveMetadataFields() []string {
	return []string{"token", "secret", "password", "cookie", "csrf", "auth_dump", "raw_auth"}
}
