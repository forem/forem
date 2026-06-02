package search

import (
	"context"
	"fmt"
)

const (
	DocumentFamilyArticles = "articles"
	DocumentFamilyComments = "comments"
	DocumentFamilyUsers    = "users"
	DocumentFamilyTags     = "tags"
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

type Provider interface {
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

type SearchResult struct {
	Provider string
	Hits     []DocumentHit
}

type DocumentHit struct {
	Family string
	ID     string
	Title  string
}

type Document interface {
	DocumentFamily() string
	DocumentID() string
}

type ArticleDocument struct {
	ID    string
	Title string
}

func (d ArticleDocument) DocumentFamily() string { return DocumentFamilyArticles }
func (d ArticleDocument) DocumentID() string     { return d.ID }

type CommentDocument struct {
	ID        string
	ArticleID string
	Body      string
}

func (d CommentDocument) DocumentFamily() string { return DocumentFamilyComments }
func (d CommentDocument) DocumentID() string     { return d.ID }

type UserDocument struct {
	ID       string
	Username string
	Name     string
}

func (d UserDocument) DocumentFamily() string { return DocumentFamilyUsers }
func (d UserDocument) DocumentID() string     { return d.ID }

type TagDocument struct {
	ID   string
	Name string
}

func (d TagDocument) DocumentFamily() string { return DocumentFamilyTags }
func (d TagDocument) DocumentID() string     { return d.ID }
