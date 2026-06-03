package search

import (
	"context"
	"fmt"
	"strings"
)

const (
	DocumentFamilyArticles = "articles"
	DocumentFamilyComments = "comments"
	DocumentFamilyUsers    = "users"
	DocumentFamilyTags     = "tags"
)

const (
	DefaultSearchLimit = 20
	MaxSearchLimit     = 100
)

type IndexFamily struct {
	Prefix  string
	Version string
}

func (f IndexFamily) VersionedIndex(documentFamily string) string {
	return fmt.Sprintf("%s-%s-%s", f.Prefix, documentFamily, f.Version)
}

func (f IndexFamily) ReadAlias(documentFamily string) string {
	return fmt.Sprintf("%s-%s-read", f.Prefix, documentFamily)
}

func (f IndexFamily) WriteAlias(documentFamily string) string {
	return fmt.Sprintf("%s-%s-write", f.Prefix, documentFamily)
}

type TransportRequest struct {
	Method string
	Path   string
	Body   []byte
}

type TransportResponse struct {
	StatusCode int
	Body       []byte
}

type Transport interface {
	Do(ctx context.Context, req TransportRequest) (TransportResponse, error)
}

type Provider interface {
	Name() string
	Search(ctx context.Context, req SearchRequest) (*SearchResult, error)
	UpsertArticle(ctx context.Context, article ArticleDocument) error
	DeleteArticle(ctx context.Context, id string) error
	UpsertComment(ctx context.Context, comment CommentDocument) error
	DeleteComment(ctx context.Context, id string) error
	UpsertUser(ctx context.Context, user UserDocument) error
	UpsertTag(ctx context.Context, tag TagDocument) error
	BulkIndex(ctx context.Context, batch []Document) error
	EnsureIndexes(ctx context.Context) error
}

type SearchRequest struct {
	Query string
	Limit int
}

func NormalizeSearchRequest(req SearchRequest) SearchRequest {
	req.Query = strings.TrimSpace(req.Query)
	if req.Limit <= 0 {
		req.Limit = DefaultSearchLimit
	}
	if req.Limit > MaxSearchLimit {
		req.Limit = MaxSearchLimit
	}
	return req
}

type SearchResult struct {
	Provider string        `json:"provider"`
	Query    string        `json:"query"`
	Limit    int           `json:"limit"`
	Hits     []DocumentHit `json:"hits"`
}

type DocumentHit struct {
	Family string `json:"family"`
	ID     string `json:"id"`
	Title  string `json:"title"`
}

type Document interface {
	DocumentFamily() string
	DocumentID() string
}

type ArticleDocument struct {
	ID    string `json:"id"`
	Title string `json:"title"`
}

func (d ArticleDocument) DocumentFamily() string { return DocumentFamilyArticles }
func (d ArticleDocument) DocumentID() string     { return d.ID }

type CommentDocument struct {
	ID        string `json:"id"`
	ArticleID string `json:"article_id"`
	Body      string `json:"body"`
}

func (d CommentDocument) DocumentFamily() string { return DocumentFamilyComments }
func (d CommentDocument) DocumentID() string     { return d.ID }

type UserDocument struct {
	ID       string `json:"id"`
	Username string `json:"username"`
	Name     string `json:"name"`
}

func (d UserDocument) DocumentFamily() string { return DocumentFamilyUsers }
func (d UserDocument) DocumentID() string     { return d.ID }

type TagDocument struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

func (d TagDocument) DocumentFamily() string { return DocumentFamilyTags }
func (d TagDocument) DocumentID() string     { return d.ID }
