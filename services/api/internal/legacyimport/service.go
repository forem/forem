package legacyimport

import (
	"context"
	"errors"

	noemaidentity "github.com/agentwego/noema/services/api/internal/identity"
	"github.com/agentwego/noema/services/api/internal/persistence"
	"github.com/agentwego/noema/services/api/internal/search"
)

const ImportPreviewSchemaVersion = "noema.legacy-import.preview/v1"
const ImportBatchPreviewSchemaVersion = "noema.legacy-import.batch-preview/v1"
const ImportPreviewSideEffects = "none-local-preview-only"

var ErrEmptyImportBatch = errors.New("legacy import batch must contain at least one item")

// PreviewService composes legacy Forem import DTO mapping, Noema-native
// persistence/search projections, and the local Ory Kratos target adapter spec.
// It is deliberately provider-free: no DB writes, no search indexing, no S3, no
// Kratos HTTP calls, no sessions/cookies, and no irreversible mutation.
type PreviewService struct {
	kratos noemaidentity.KratosTargetAdapter
}

type PreviewServiceOptions struct {
	Kratos noemaidentity.KratosTargetAdapter
}

type ImportPreview struct {
	SchemaVersion string                    `json:"schema_version"`
	Bundle        ArticleUserIdentityBundle `json:"bundle"`
	Persistence   PersistencePreview        `json:"persistence"`
	Search        SearchPreview             `json:"search"`
	Kratos        KratosPreview             `json:"kratos"`
	SideEffects   string                    `json:"side_effects"`
}

type PersistencePreview struct {
	User    persistence.User    `json:"user"`
	Article persistence.Article `json:"article"`
}

type SearchPreview struct {
	User    search.UserDocument    `json:"user"`
	Article search.ArticleDocument `json:"article"`
}

type KratosPreview struct {
	Identity         noemaidentity.KratosIdentityImport    `json:"identity"`
	Session          noemaidentity.KratosSession           `json:"session"`
	SelfServiceFlows []noemaidentity.KratosSelfServiceFlow `json:"self_service_flows"`
	OperationPlans   []noemaidentity.KratosOperationPlan   `json:"operation_plans"`
}

type ImportBatchPreviewRequest struct {
	Items []ForemArticleUserIdentityImport `json:"items"`
}

type ImportBatchPreview struct {
	SchemaVersion string                   `json:"schema_version"`
	Total         int                      `json:"total"`
	Succeeded     int                      `json:"succeeded"`
	Failed        int                      `json:"failed"`
	Items         []ImportBatchPreviewItem `json:"items"`
	SideEffects   string                   `json:"side_effects"`
}

type ImportBatchPreviewItem struct {
	Index   int            `json:"index"`
	Preview *ImportPreview `json:"preview,omitempty"`
	Error   string         `json:"error,omitempty"`
}

func NewPreviewService(options PreviewServiceOptions) PreviewService {
	kratos := options.Kratos
	if kratos == nil {
		kratos = noemaidentity.NewLocalKratosAdapter()
	}
	return PreviewService{kratos: kratos}
}

func (s PreviewService) PreviewForemArticleUserIdentity(ctx context.Context, input ForemArticleUserIdentityImport) (ImportPreview, error) {
	bundle, err := BuildForemArticleUserIdentityBundle(input)
	if err != nil {
		return ImportPreview{}, err
	}

	identityPreview, err := s.kratos.PreviewIdentityImport(ctx, bundle.Identity.KratosIdentity)
	if err != nil {
		return ImportPreview{}, err
	}
	sessionPreview, err := s.kratos.PreviewSession(ctx, identityPreview.ID)
	if err != nil {
		return ImportPreview{}, err
	}
	flowPreviews, err := s.kratos.PreviewSelfServiceFlows(ctx, "")
	if err != nil {
		return ImportPreview{}, err
	}
	operationPlans, err := s.previewKratosOperationPlans(ctx, bundle.Identity.KratosIdentity)
	if err != nil {
		return ImportPreview{}, err
	}

	return ImportPreview{
		SchemaVersion: ImportPreviewSchemaVersion,
		Bundle:        bundle,
		Persistence: PersistencePreview{
			User:    bundle.User.ToPersistence(),
			Article: bundle.Article.ToPersistence(),
		},
		Search: SearchPreview{
			User:    bundle.User.ToSearchDocument(),
			Article: bundle.Article.ToSearchDocument(),
		},
		Kratos: KratosPreview{
			Identity:         identityPreview,
			Session:          sessionPreview,
			SelfServiceFlows: flowPreviews,
			OperationPlans:   operationPlans,
		},
		SideEffects: ImportPreviewSideEffects,
	}, nil
}

func (s PreviewService) PreviewForemArticleUserIdentityBatch(ctx context.Context, request ImportBatchPreviewRequest) (ImportBatchPreview, error) {
	if len(request.Items) == 0 {
		return ImportBatchPreview{}, ErrEmptyImportBatch
	}

	batch := ImportBatchPreview{
		SchemaVersion: ImportBatchPreviewSchemaVersion,
		Total:         len(request.Items),
		Items:         make([]ImportBatchPreviewItem, 0, len(request.Items)),
		SideEffects:   ImportPreviewSideEffects,
	}
	for index, input := range request.Items {
		preview, err := s.PreviewForemArticleUserIdentity(ctx, input)
		item := ImportBatchPreviewItem{Index: index}
		if err != nil {
			item.Error = err.Error()
			batch.Failed++
		} else {
			item.Preview = &preview
			batch.Succeeded++
		}
		batch.Items = append(batch.Items, item)
	}
	return batch, nil
}

func (s PreviewService) previewKratosOperationPlans(ctx context.Context, input noemaidentity.KratosIdentityImport) ([]noemaidentity.KratosOperationPlan, error) {
	identityPlan, err := s.kratos.PreviewIdentityImportOperation(ctx, input)
	if err != nil {
		return nil, err
	}
	sessionPlan, err := s.kratos.PreviewSessionWhoAmIOperation(ctx)
	if err != nil {
		return nil, err
	}
	flowPlans := make([]noemaidentity.KratosOperationPlan, 0, 5)
	for _, kind := range []noemaidentity.KratosSelfServiceFlowKind{
		noemaidentity.KratosFlowLogin,
		noemaidentity.KratosFlowRegistration,
		noemaidentity.KratosFlowSettings,
		noemaidentity.KratosFlowRecovery,
		noemaidentity.KratosFlowVerification,
	} {
		plan, err := s.kratos.PreviewSelfServiceFlowOperation(ctx, kind, "")
		if err != nil {
			return nil, err
		}
		flowPlans = append(flowPlans, plan)
	}
	plans := []noemaidentity.KratosOperationPlan{identityPlan, sessionPlan}
	plans = append(plans, flowPlans...)
	return plans, nil
}
