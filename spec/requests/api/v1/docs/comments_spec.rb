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

### Threaded Structure & Pagination Tips:
- **Threaded Format**: Comments are returned as a tree structure (nested arrays of replies). Each top-level comment contains its nested child comments recursively.
- **Query Constraints**: You must provide either `a_id` (Article ID) OR `p_id` (Podcast Episode ID) to fetch comments. Specifying both is not supported.
- **Pagination**: When paginating, the `page` parameter filters the *top-level* comments only. All replies to those top-level comments are returned nested inline, regardless of page index.
- If the `page` parameter is omitted, the response returns the full comment tree in a single payload."
        operationId "getCommentsByArticleId"
        produces "application/json"
        parameter "$ref": "#/components/parameters/pageParam"
        parameter "$ref": "#/components/parameters/perPageParam30to1000"
        parameter name: :a_id, in: :query, required: false,
                  description: "Article identifier. Provide this to fetch comments belonging to a specific article.",
                  schema: { type: :string },
                  example: "321"
        parameter name: :p_id, in: :query, required: false,
                  description: "Podcast Episode identifier. Provide this to fetch comments belonging to a specific podcast episode.",
                  schema: { type: :string },
                  example: "321"
        parameter name: :page, in: :query, required: false,
                  description: "Pagination page index for top-level comments.",
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
        description "This endpoint allows the client to retrieve a specific comment and all of its nested descendant replies.

### Integration Tip:
- Handy for linking directly to a deep comment thread or loading individual comment replies on demand."
        operationId "getCommentById"
        produces "application/json"
        parameter name: :id, in: :path, required: false,
                  description: "Comment identifier (the unique alpha-numeric `id_code` of the comment).",
                  schema: { type: :string },
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
