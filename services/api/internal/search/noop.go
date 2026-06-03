package search

import (
	"context"
	"errors"
)

var ErrNoopReadOnly = errors.New("noop search provider is read-only")

type noopProvider struct{}

func NewNoopProvider() Provider {
	return noopProvider{}
}

func (noopProvider) Name() string { return "noop" }

func (noopProvider) Search(_ context.Context, req SearchRequest) (*SearchResult, error) {
	req = NormalizeSearchRequest(req)
	return &SearchResult{Provider: "noop", Query: req.Query, Limit: req.Limit, Hits: []DocumentHit{}}, nil
}

func (noopProvider) UpsertArticle(context.Context, ArticleDocument) error { return ErrNoopReadOnly }
func (noopProvider) DeleteArticle(context.Context, string) error          { return ErrNoopReadOnly }
func (noopProvider) UpsertComment(context.Context, CommentDocument) error { return ErrNoopReadOnly }
func (noopProvider) DeleteComment(context.Context, string) error          { return ErrNoopReadOnly }
func (noopProvider) UpsertUser(context.Context, UserDocument) error       { return ErrNoopReadOnly }
func (noopProvider) UpsertTag(context.Context, TagDocument) error         { return ErrNoopReadOnly }
func (noopProvider) BulkIndex(context.Context, []Document) error          { return ErrNoopReadOnly }
func (noopProvider) EnsureIndexes(context.Context) error                  { return ErrNoopReadOnly }
