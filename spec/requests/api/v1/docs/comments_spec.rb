require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::Comments" do
  let(:article) { create(:article) }
  let!(:comments) { create(:comment, commentable_type: "Article", commentable_id: article.id) }
  let(:Accept) { "application/vnd.forem.api-v1+json" }

  describe "GET /comments" do
    path "/api/comments" do
      get "Comments" do
        security []
        tags "comments"
        description "This endpoint allows the client to retrieve all comments belonging to an article or podcast episode as threaded conversations.

It will return the all top level comments with their nested comments as threads. See the format specification for further details.

It supports pagination, each page will contain `50` top level comments (and as many child comments they have) by default.

If the page parameter is not passed, all comments of an article or podcast will be returned.
"
        operationId "getCommentsByArticleId"
        produces "application/json"
        parameter "$ref": "#/components/parameters/pageParam"
        parameter "$ref": "#/components/parameters/perPageParam30to1000"
        parameter name: :a_id, in: :query, required: false,
                  description: "Article identifier.",
                  schema: { type: :string },
                  example: "321"
        parameter name: :p_id, in: :query, required: false,
                  description: "Podcast Episode identifier.",
                  schema: { type: :string },
                  example: "321"
        parameter name: :page, in: :query, required: false,
                  description: "Page",
                  schema: { type: :string },
                  example: "321"

        response "200", "A List of Comments" do
          let(:a_id) { article.id }
          schema  type: :array,
                  items: { "$ref": "#/components/schemas/Comment" }
          add_examples

          run_test!
        end

        response "404", "Resource Not Found" do
          let(:id) { 1_000_000 }
          add_examples

          run_test!
        end
      end
    end
  end

  describe "GET /comments/{id}" do
    path "/api/comments/{id}" do
      get "Comment by id" do
        security []
        tags "comments"
        description "This endpoint allows the client to retrieve a comment as well as his descendants comments.

  It will return the required comment (the root) with its nested descendants as a thread.

  See the format specification for further details."
        operationId "getCommentById"
        produces "application/json"
        parameter name: :id, in: :path, required: false,
                  description: "Comment identifier.",
                  schema: { type: :integer },
                  example: "321"

        response "200", "A List of the Comments" do
          let(:id) { comments.id_code }
          add_examples

          run_test!
        end

        response "404", "Comment Not Found" do
          let(:id) { 1_000_000 }
          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable Layout/LineLength
