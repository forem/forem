package search

import "context"

type noopProvider struct{}

func NewNoopProvider() Provider {
	return noopProvider{}
}

func (noopProvider) Search(_ context.Context, req SearchRequest) (*SearchResult, error) {
	req = NormalizeSearchRequest(req)
	return &SearchResult{Provider: "noop", Query: req.Query, Limit: req.Limit, Hits: []DocumentHit{}}, nil
}

func (noopProvider) UpsertArticle(context.Context, ArticleDocument) error { return nil }
func (noopProvider) DeleteArticle(context.Context, string) error          { return nil }
func (noopProvider) UpsertComment(context.Context, CommentDocument) error { return nil }
func (noopProvider) DeleteComment(context.Context, string) error          { return nil }
func (noopProvider) UpsertUser(context.Context, UserDocument) error       { return nil }
func (noopProvider) UpsertTag(context.Context, TagDocument) error         { return nil }
func (noopProvider) BulkIndex(context.Context, []Document) error          { return nil }
func (noopProvider) EnsureIndexes(context.Context) error                  { return nil }
