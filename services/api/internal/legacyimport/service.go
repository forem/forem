package legacyimport

import (
	"context"

	noemaidentity "github.com/agentwego/noema/services/api/internal/identity"
	"github.com/agentwego/noema/services/api/internal/persistence"
	"github.com/agentwego/noema/services/api/internal/search"
)

const ImportPreviewSchemaVersion = "noema.legacy-import.preview/v1"
const ImportPreviewSideEffects = "none-local-preview-only"

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
		},
		SideEffects: ImportPreviewSideEffects,
	}, nil
}
