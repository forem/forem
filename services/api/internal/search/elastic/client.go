package elastic

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"strings"

	"github.com/agentwego/noema/services/api/internal/search"
)

const providerName = "elasticsearch"

type Provider struct {
	family    search.IndexFamily
	analyzer  string
	transport search.Transport
}

func init() {
	search.RegisterProvider(providerName, NewProvider)
}

func NewProvider(options search.ProviderOptions) (search.Provider, error) {
	if options.Transport == nil {
		return nil, errors.New("elasticsearch provider requires explicit transport")
	}
	family := options.IndexFamily
	if family.Prefix == "" {
		family.Prefix = "noema"
	}
	if family.Version == "" {
		family.Version = "v1"
	}
	analyzer := options.Analyzer
	if analyzer == "" {
		analyzer = AnalyzerNGram
	}
	if analyzer != AnalyzerNGram && analyzer != AnalyzerIK {
		return nil, fmt.Errorf("unknown analyzer %q", analyzer)
	}
	return &Provider{family: family, analyzer: analyzer, transport: options.Transport}, nil
}

func (p *Provider) Name() string { return providerName }

func (p *Provider) EnsureIndexes(ctx context.Context) error {
	manifest := BuildManifest(p.family, p.analyzer)
	if err := ValidateManifest(manifest); err != nil {
		return err
	}
	for _, spec := range manifest.Indexes {
		if err := p.sendJSON(ctx, "PUT", "/"+spec.IndexName, spec.Mapping); err != nil {
			return err
		}
		body := map[string]any{
			"actions": []map[string]any{
				{"add": map[string]any{"index": spec.IndexName, "alias": spec.ReadAlias}},
				{"add": map[string]any{"index": spec.IndexName, "alias": spec.WriteAlias}},
			},
		}
		if err := p.sendJSON(ctx, "POST", "/_aliases", body); err != nil {
			return err
		}
	}
	return nil
}

func (p *Provider) Search(ctx context.Context, req search.SearchRequest) (*search.SearchResult, error) {
	req = search.NormalizeSearchRequest(req)
	body := map[string]any{
		"size": req.Limit,
		"query": map[string]any{
			"multi_match": map[string]any{
				"query":  req.Query,
				"fields": []string{"title^3", "body", "tags", "author_username"},
			},
		},
	}
	payload, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}
	response, err := p.do(ctx, search.TransportRequest{
		Method: "POST",
		Path:   "/" + strings.Join(p.readAliases(), ",") + "/_search",
		Body:   payload,
	})
	if err != nil {
		return nil, err
	}
	hits, err := decodeHits(p.family, response.Body)
	if err != nil {
		return nil, err
	}
	return &search.SearchResult{Provider: providerName, Query: req.Query, Limit: req.Limit, Hits: hits}, nil
}

func (p *Provider) UpsertArticle(ctx context.Context, article search.ArticleDocument) error {
	return p.BulkIndex(ctx, []search.Document{article})
}

func (p *Provider) DeleteArticle(ctx context.Context, id string) error {
	return p.deleteDocument(ctx, search.DocumentFamilyArticles, id)
}

func (p *Provider) UpsertComment(ctx context.Context, comment search.CommentDocument) error {
	return p.BulkIndex(ctx, []search.Document{comment})
}

func (p *Provider) DeleteComment(ctx context.Context, id string) error {
	return p.deleteDocument(ctx, search.DocumentFamilyComments, id)
}

func (p *Provider) UpsertUser(ctx context.Context, user search.UserDocument) error {
	return p.BulkIndex(ctx, []search.Document{user})
}

func (p *Provider) UpsertTag(ctx context.Context, tag search.TagDocument) error {
	return p.BulkIndex(ctx, []search.Document{tag})
}

func (p *Provider) BulkIndex(ctx context.Context, batch []search.Document) error {
	if len(batch) == 0 {
		return nil
	}
	var buffer bytes.Buffer
	encoder := json.NewEncoder(&buffer)
	for _, doc := range batch {
		meta := map[string]any{
			"index": map[string]any{
				"_index": p.family.WriteAlias(doc.DocumentFamily()),
				"_id":    doc.DocumentID(),
			},
		}
		if err := encoder.Encode(meta); err != nil {
			return err
		}
		if err := encoder.Encode(documentSource(doc)); err != nil {
			return err
		}
	}
	_, err := p.do(ctx, search.TransportRequest{Method: "POST", Path: "/_bulk", Body: buffer.Bytes()})
	return err
}

func (p *Provider) sendJSON(ctx context.Context, method, path string, body any) error {
	payload, err := json.Marshal(body)
	if err != nil {
		return err
	}
	_, err = p.do(ctx, search.TransportRequest{Method: method, Path: path, Body: payload})
	return err
}

func (p *Provider) do(ctx context.Context, req search.TransportRequest) (search.TransportResponse, error) {
	response, err := p.transport.Do(ctx, req)
	if err != nil {
		return search.TransportResponse{}, err
	}
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		return search.TransportResponse{}, fmt.Errorf("elasticsearch %s %s returned status %d", req.Method, req.Path, response.StatusCode)
	}
	return response, nil
}

func (p *Provider) readAliases() []string {
	return []string{
		p.family.ReadAlias(search.DocumentFamilyArticles),
		p.family.ReadAlias(search.DocumentFamilyComments),
		p.family.ReadAlias(search.DocumentFamilyUsers),
		p.family.ReadAlias(search.DocumentFamilyTags),
	}
}

func (p *Provider) deleteDocument(ctx context.Context, family, id string) error {
	_, err := p.do(ctx, search.TransportRequest{
		Method: "DELETE",
		Path:   "/" + p.family.WriteAlias(family) + "/_doc/" + url.PathEscape(id),
	})
	return err
}

func documentSource(doc search.Document) map[string]any {
	source := map[string]any{
		"id": doc.DocumentID(),
	}
	switch typed := doc.(type) {
	case search.ArticleDocument:
		source["title"] = typed.Title
	case search.CommentDocument:
		source["article_id"] = typed.ArticleID
		source["body"] = typed.Body
	case search.UserDocument:
		source["username"] = typed.Username
		source["name"] = typed.Name
	case search.TagDocument:
		source["name"] = typed.Name
	}
	return source
}

func decodeHits(family search.IndexFamily, body []byte) ([]search.DocumentHit, error) {
	var payload struct {
		Hits struct {
			Hits []struct {
				Index  string         `json:"_index"`
				ID     string         `json:"_id"`
				Source map[string]any `json:"_source"`
			} `json:"hits"`
		} `json:"hits"`
	}
	if len(bytes.TrimSpace(body)) == 0 {
		return []search.DocumentHit{}, nil
	}
	if err := json.Unmarshal(body, &payload); err != nil {
		return nil, err
	}
	hits := make([]search.DocumentHit, 0, len(payload.Hits.Hits))
	for _, hit := range payload.Hits.Hits {
		hits = append(hits, search.DocumentHit{
			Family: documentFamilyFromIndex(family, hit.Index),
			ID:     hit.ID,
			Title:  displayTitle(hit.Source),
		})
	}
	return hits, nil
}

func documentFamilyFromIndex(family search.IndexFamily, index string) string {
	for _, documentFamily := range []string{search.DocumentFamilyArticles, search.DocumentFamilyComments, search.DocumentFamilyUsers, search.DocumentFamilyTags} {
		if index == family.VersionedIndex(documentFamily) || strings.Contains(index, "-"+documentFamily+"-") {
			return documentFamily
		}
	}
	return ""
}

func displayTitle(source map[string]any) string {
	for _, key := range []string{"title", "name", "username", "body"} {
		if value, ok := source[key].(string); ok && value != "" {
			return value
		}
	}
	return ""
}
