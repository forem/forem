package legacyimport_test

import (
	"testing"

	"github.com/agentwego/noema/services/api/internal/legacyimport"
)

func TestBuildForemArticleUserIdentityBundleComposesCleanDTOsAndKratosBoundary(t *testing.T) {
	payload := readFixture(t)

	bundle, err := legacyimport.BuildForemArticleUserIdentityBundle(legacyimport.ForemArticleUserIdentityImport{
		Article: payload.Article,
		Email:   "alice@example.com",
		ExternalIdentities: []legacyimport.ForemExternalIdentity{
			{Provider: "github", UID: "alice-gh"},
		},
	})
	if err != nil {
		t.Fatalf("BuildForemArticleUserIdentityBundle returned error: %v", err)
	}

	if bundle.User.ID != "42" || bundle.User.Username != "alice" || bundle.User.DisplayName != "Alice Example" {
		t.Fatalf("unexpected clean user dto: %+v", bundle.User)
	}
	if bundle.Article.ID != "123456" || bundle.Article.AuthorID != bundle.User.ID || bundle.Article.Title != "Hello Noema" {
		t.Fatalf("unexpected clean article dto: %+v", bundle.Article)
	}
	if got := bundle.Article.Tags; len(got) != 2 || got[0] != "go" || got[1] != "native" {
		t.Fatalf("unexpected clean article tags: %+v", got)
	}
	if bundle.Identity.User.ID != bundle.User.ID || bundle.Identity.User.Username != bundle.User.Username {
		t.Fatalf("identity boundary does not reuse clean user dto: user=%+v identity=%+v", bundle.User, bundle.Identity.User)
	}
	if bundle.Identity.KratosIdentity.Traits.Email != "alice@example.com" {
		t.Fatalf("unexpected Kratos identity traits: %+v", bundle.Identity.KratosIdentity.Traits)
	}
	if bundle.Identity.KratosIdentity.MetadataAdmin["legacy_identity_github"] != "github:alice-gh" {
		t.Fatalf("missing legacy provider subject in Kratos admin metadata: %+v", bundle.Identity.KratosIdentity.MetadataAdmin)
	}
}

func TestBuildForemArticleUserIdentityBundleAcceptsExplicitForemUser(t *testing.T) {
	payload := readFixture(t)
	article := payload.Article
	article.User = legacyimport.ForemUser{}
	article.UserID = payload.Article.User.ID

	bundle, err := legacyimport.BuildForemArticleUserIdentityBundle(legacyimport.ForemArticleUserIdentityImport{
		Article: article,
		User:    payload.Article.User,
		Email:   "alice@example.com",
	})
	if err != nil {
		t.Fatalf("BuildForemArticleUserIdentityBundle returned error: %v", err)
	}

	if bundle.User.ID != "42" || bundle.Article.AuthorID != "42" {
		t.Fatalf("explicit user was not mapped into clean user/article DTOs: %+v", bundle)
	}
	if bundle.Identity.KratosIdentity.MetadataAdmin["legacy_forem_user_id"] != "42" {
		t.Fatalf("explicit user was not reserved in Kratos admin metadata: %+v", bundle.Identity.KratosIdentity.MetadataAdmin)
	}
}
