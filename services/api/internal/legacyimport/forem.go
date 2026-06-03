package legacyimport

import (
	"errors"
	"strconv"
	"strings"
	"time"

	"github.com/agentwego/noema/services/api/internal/persistence"
	"github.com/agentwego/noema/services/api/internal/search"
)

var (
	ErrMissingUserID       = errors.New("legacy user id is required")
	ErrMissingUsername     = errors.New("legacy username is required")
	ErrMissingArticleID    = errors.New("legacy article id is required")
	ErrMissingArticleSlug  = errors.New("legacy article slug is required")
	ErrMissingArticleTitle = errors.New("legacy article title is required")
	ErrMissingArticleBody  = errors.New("legacy article body_markdown is required")
	ErrMissingArticleUser  = errors.New("legacy article user_id is required")
)

// ForemUser is the small import-facing shape accepted from Forem exports or
// fixtures. It intentionally keeps only fields needed by the first Noema-native
// identity DTO and ignores authentication/profile extras from the legacy model.
type ForemUser struct {
	ID           int64     `json:"id"`
	Username     string    `json:"username"`
	Name         string    `json:"name"`
	ProfileImage string    `json:"profile_image"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// ForemArticle is the small import-facing shape accepted from Forem article
// exports. Rich legacy fields remain out of this boundary until a later slice
// gives them a Noema-native owner.
type ForemArticle struct {
	ID            int64      `json:"id"`
	UserID        int64      `json:"user_id"`
	Title         string     `json:"title"`
	BodyMarkdown  string     `json:"body_markdown"`
	Slug          string     `json:"slug"`
	Published     bool       `json:"published"`
	PublishedAt   *time.Time `json:"published_at"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`
	TagList       []string   `json:"tag_list"`
	CachedTagList string     `json:"cached_tag_list"`
	User          ForemUser  `json:"user"`
}

// UserDTO is the clean Noema import DTO for legacy Forem users.
type UserDTO struct {
	ID           string    `json:"id"`
	Username     string    `json:"username"`
	DisplayName  string    `json:"display_name"`
	ProfileImage string    `json:"profile_image,omitempty"`
	CreatedAt    time.Time `json:"created_at,omitempty"`
	UpdatedAt    time.Time `json:"updated_at,omitempty"`
}

// ArticleDTO is the clean Noema import DTO for legacy Forem articles.
type ArticleDTO struct {
	ID           string     `json:"id"`
	AuthorID     string     `json:"author_id"`
	Slug         string     `json:"slug"`
	Title        string     `json:"title"`
	BodyMarkdown string     `json:"body_markdown"`
	Published    bool       `json:"published"`
	PublishedAt  *time.Time `json:"published_at,omitempty"`
	CreatedAt    time.Time  `json:"created_at,omitempty"`
	UpdatedAt    time.Time  `json:"updated_at,omitempty"`
	Tags         []string   `json:"tags"`
}

func MapForemUser(user ForemUser) (UserDTO, error) {
	if user.ID == 0 {
		return UserDTO{}, ErrMissingUserID
	}
	username := strings.TrimSpace(user.Username)
	if username == "" {
		return UserDTO{}, ErrMissingUsername
	}
	displayName := strings.TrimSpace(user.Name)
	if displayName == "" {
		displayName = username
	}
	return UserDTO{
		ID:           strconv.FormatInt(user.ID, 10),
		Username:     username,
		DisplayName:  displayName,
		ProfileImage: user.ProfileImage,
		CreatedAt:    user.CreatedAt,
		UpdatedAt:    user.UpdatedAt,
	}, nil
}

func MapForemArticle(article ForemArticle) (ArticleDTO, error) {
	if article.ID == 0 {
		return ArticleDTO{}, ErrMissingArticleID
	}
	if article.UserID == 0 && article.User.ID != 0 {
		article.UserID = article.User.ID
	}
	if article.UserID == 0 {
		return ArticleDTO{}, ErrMissingArticleUser
	}
	slug := strings.TrimSpace(article.Slug)
	if slug == "" {
		return ArticleDTO{}, ErrMissingArticleSlug
	}
	title := strings.TrimSpace(article.Title)
	if title == "" {
		return ArticleDTO{}, ErrMissingArticleTitle
	}
	if article.BodyMarkdown == "" {
		return ArticleDTO{}, ErrMissingArticleBody
	}
	return ArticleDTO{
		ID:           strconv.FormatInt(article.ID, 10),
		AuthorID:     strconv.FormatInt(article.UserID, 10),
		Slug:         slug,
		Title:        title,
		BodyMarkdown: article.BodyMarkdown,
		Published:    article.Published,
		PublishedAt:  article.PublishedAt,
		CreatedAt:    article.CreatedAt,
		UpdatedAt:    article.UpdatedAt,
		Tags:         normalizeTags(article.TagList, article.CachedTagList),
	}, nil
}

func normalizeTags(tagList []string, cachedTagList string) []string {
	if len(tagList) == 0 && strings.TrimSpace(cachedTagList) != "" {
		tagList = strings.Split(cachedTagList, ",")
	}
	tags := make([]string, 0, len(tagList))
	for _, tag := range tagList {
		tag = strings.TrimSpace(tag)
		if tag != "" {
			tags = append(tags, tag)
		}
	}
	return tags
}

func (dto UserDTO) ToPersistence() persistence.User {
	return persistence.User{
		ID:          dto.ID,
		Username:    dto.Username,
		DisplayName: dto.DisplayName,
		CreatedAt:   dto.CreatedAt,
		UpdatedAt:   dto.UpdatedAt,
	}
}

func (dto UserDTO) ToSearchDocument() search.UserDocument {
	return search.UserDocument{
		ID:       dto.ID,
		Username: dto.Username,
		Name:     dto.DisplayName,
	}
}

func (dto ArticleDTO) ToPersistence() persistence.Article {
	return persistence.Article{
		ID:           dto.ID,
		AuthorID:     dto.AuthorID,
		Slug:         dto.Slug,
		Title:        dto.Title,
		BodyMarkdown: dto.BodyMarkdown,
		Published:    dto.Published,
		PublishedAt:  dto.PublishedAt,
		CreatedAt:    dto.CreatedAt,
		UpdatedAt:    dto.UpdatedAt,
	}
}

func (dto ArticleDTO) ToSearchDocument() search.ArticleDocument {
	return search.ArticleDocument{
		ID:    dto.ID,
		Title: dto.Title,
	}
}
