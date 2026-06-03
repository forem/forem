package legacyimport

// ForemArticleUserIdentityImport is the local-only import preview input that
// composes one legacy Forem article, its embedded user, and safe identity hints.
// It deliberately excludes passwords, OAuth tokens/secrets, raw auth dumps,
// sessions, cookies, and any external provider I/O.
type ForemArticleUserIdentityImport struct {
	Article            ForemArticle            `json:"article"`
	User               ForemUser               `json:"user"`
	Email              string                  `json:"email"`
	ExternalIdentities []ForemExternalIdentity `json:"external_identities"`
}

// ArticleUserIdentityBundle is the clean Noema bundle emitted before any
// persistence, search indexing, or Kratos API call. It keeps article/user domain
// DTOs separate from the Ory Kratos identity boundary so auth does not regress
// into a custom long-lived Noema authentication system.
type ArticleUserIdentityBundle struct {
	User     UserDTO              `json:"user"`
	Article  ArticleDTO           `json:"article"`
	Identity UserIdentityBoundary `json:"identity"`
}

func BuildForemArticleUserIdentityBundle(input ForemArticleUserIdentityImport) (ArticleUserIdentityBundle, error) {
	legacyUser := input.User
	if legacyUser.ID == 0 {
		legacyUser = input.Article.User
	}

	user, err := MapForemUser(legacyUser)
	if err != nil {
		return ArticleUserIdentityBundle{}, err
	}

	articleInput := input.Article
	if articleInput.User.ID == 0 {
		articleInput.User = legacyUser
	}
	article, err := MapForemArticle(articleInput)
	if err != nil {
		return ArticleUserIdentityBundle{}, err
	}

	identityBoundary, err := MapForemUserIdentity(ForemUserIdentity{
		User:               legacyUser,
		Email:              input.Email,
		ExternalIdentities: input.ExternalIdentities,
	})
	if err != nil {
		return ArticleUserIdentityBundle{}, err
	}

	return ArticleUserIdentityBundle{
		User:     user,
		Article:  article,
		Identity: identityBoundary,
	}, nil
}
