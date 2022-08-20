require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::Articles", type: :request do
  let(:organization) { create(:organization) } # not used by every spec but lower times overall
  let(:tag) { create(:tag, :with_colors, name: "discuss") }
  let(:article) { create(:article, featured: true, tags: "discuss", published: true) }
  let(:unpublished_aricle) { create(:article, published: false) }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }
  let(:Accept) { "application/vnd.forem.api-v1+json" }

  before do
    stub_const("FlareTag::FLARE_TAG_IDS_HASH", { "discuss" => tag.id })
    allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true)
  end

  describe "GET /articles" do
    before do
      article.update_columns(organization_id: organization.id)
    end

    path "/api/articles" do
      get "Published articles" do
        security []
        tags "articles"
        description "This endpoint allows the client to retrieve a list of articles.

\"Articles\" are all the posts that users create on DEV that typically
show up in the feed. They can be a blog post, a discussion question,
a help thread etc. but is referred to as article within the code.

By default it will return featured, published articles ordered
by descending popularity.

It supports pagination, each page will contain `30` articles by default."
        operationId "getArticles"
        produces "application/json"
        parameter "$ref": "#/components/parameters/pageParam"
        parameter "$ref": "#/components/parameters/perPageParam30to1000"
        parameter name: :tag, in: :query, required: false,
                  description: "Using this parameter will retrieve articles that contain the requested tag. Articles
will be ordered by descending popularity.This parameter can be used in conjuction with `top`.",
                  schema: { type: :string },
                  example: "discuss"
        parameter name: :tags, in: :query, required: false,
                  description: "Using this parameter will retrieve articles with any of the comma-separated tags.
Articles will be ordered by descending popularity.",
                  schema: { type: :string },
                  example: "javascript, css"
        parameter name: :tags_exclude, in: :query, required: false,
                  description: "Using this parameter will retrieve articles that do _not_ contain _any_
of comma-separated tags. Articles will be ordered by descending popularity.",
                  schema: { type: :string },
                  example: "node, java"
        parameter name: :username, in: :query, required: false,
                  description: "Using this parameter will retrieve articles belonging
            to a User or Organization ordered by descending publication date.
            If `state=all` the number of items returned will be `1000` instead of the default `30`.
            This parameter can be used in conjuction with `state`.",
                  schema: { type: :string },
                  example: "ben"
        parameter name: :state, in: :query, required: false,
                  description: "Using this parameter will allow the client to check which articles are fresh or rising.
            If `state=fresh` the server will return fresh articles.
            If `state=rising` the server will return rising articles.
            This param can be used in conjuction with `username`, only if set to `all`.",
                  schema: {
                    type: :string,
                    enum: %i[fresh rising all]
                  },
                  example: "fresh"
        parameter name: :top, in: :query, required: false,
                  description: "Using this parameter will allow the client to return the most popular articles
in the last `N` days.
`top` indicates the number of days since publication of the articles returned.
This param can be used in conjuction with `tag`.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 2
        parameter name: :collection_id, in: :query, required: false,
                  description: "Adding this will allow the client to return the list of articles
belonging to the requested collection, ordered by ascending publication date.",
                  schema: {
                    type: :integer,
                    format: :int32
                  },
                  example: 99

        response "200", "A List of Articles" do
          let(:"api-key") { nil }
          schema  type: :array,
                  items: { "$ref": "#/components/schemas/ArticleIndex" }
          add_examples

          run_test!
        end
      end
    end
  end

  describe "PUT /articles/:id/unpublish" do
    before do
      user.add_role(:admin)
    end

    path "/api/articles/{id}/unpublish" do
      put "Unpublish an article" do
        tags "articles"
        description "This endpoint allows the client to unpublish an article.

The user associated with the API key must have any 'admin' or 'moderator' role.

The article will be unpublished and will no longer be visible to the public. It will remain
in the database and will set back to draft status on the author's posts dashboard. Any
notifications associated with the article will be deleted. Any comments on the article
will remain."
        operationId "unpublishArticle"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The ID of the article to unpublish.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 1

        response "204", "Article successfully unpublished" do
          let(:"api-key") { api_secret.secret }
          let(:id) { article.id }
          add_examples

          run_test!
        end

        response "401", "Article already unpublished" do
          let(:"api-key") { api_secret.secret }
          let(:id) { unpublished_aricle.id }
          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:regular_user) { create(:user) }
          let(:low_security_api_secret) { create(:api_secret, user: regular_user) }
          let(:"api-key") { low_security_api_secret.secret }
          let(:id) { unpublished_aricle.id }
          add_examples

          run_test!
        end

        response "404", "Article Not Found" do
          let(:"api-key") { api_secret.secret }
          let(:id) { 0 }
          add_examples

          run_test!
        end
      end
    end
  end
  # rubocop:enable RSpec/VariableName
  # rubocop:enable RSpec/EmptyExampleGroup
end
