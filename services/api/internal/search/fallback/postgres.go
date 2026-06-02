package fallback

import (
	"context"
	"errors"

	"github.com/agentwego/noema/services/api/internal/search"
)

var ErrReadOnly = errors.New("postgres search fallback is read-only")

type postgresProvider struct{}

func init() {
	search.RegisterProvider("postgres", func(search.ProviderOptions) (search.Provider, error) {
		return NewPostgresProvider(), nil
	})
}

func NewPostgresProvider() search.Provider {
	return postgresProvider{}
}

func (postgresProvider) Name() string { return "postgres" }

func (postgresProvider) Search(_ context.Context, req search.SearchRequest) (*search.SearchResult, error) {
	req = search.NormalizeSearchRequest(req)
	return &search.SearchResult{Provider: "postgres", Query: req.Query, Limit: req.Limit, Hits: []search.DocumentHit{}}, nil
}

func (postgresProvider) EnsureIndexes(context.Context) error { return ErrReadOnly }

func (postgresProvider) UpsertArticle(context.Context, search.ArticleDocument) error {
	return ErrReadOnly
}
func (postgresProvider) DeleteArticle(context.Context, string) error { return ErrReadOnly }
func (postgresProvider) UpsertComment(context.Context, search.CommentDocument) error {
	return ErrReadOnly
}
func (postgresProvider) DeleteComment(context.Context, string) error           { return ErrReadOnly }
func (postgresProvider) UpsertUser(context.Context, search.UserDocument) error { return ErrReadOnly }
func (postgresProvider) UpsertTag(context.Context, search.TagDocument) error   { return ErrReadOnly }
func (postgresProvider) BulkIndex(context.Context, []search.Document) error    { return ErrReadOnly }
