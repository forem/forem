require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::Readinglist" do
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }
  let(:readinglist) { create_list(:reading_reaction, 3, user: user) }
  let(:Accept) { "application/vnd.forem.api-v1+json" }

  before { user.add_role(:admin) }

  describe "GET /readinglist" do
    path "/api/readinglist" do
      get "Readinglist" do
        tags "readinglist"
        description(<<-DESCRIBE.strip)
        Retrieve the list of articles saved to the authenticated user's reading list.

        ### Integration Guidance:
        - Requires authentication.
        - Under the hood, this endpoint retrieves articles that the user has reacted to with the `"save"` reaction category.
        - Supports pagination, defaulting to 30 articles per page.
        - Returned objects conform to the standard `ArticleIndex` schema.
        DESCRIBE
        operationId "getReadinglist"
        produces "application/json"
        parameter "$ref": "#/components/parameters/pageParam"
        parameter "$ref": "#/components/parameters/perPageParam30to1000"

        response "401", "Unauthorized" do
          let(:"api-key") { nil }
          add_examples

          run_test!
        end

        response "200", "A list of articles in the users readinglist" do
          let(:"api-key") { api_secret.secret }
          schema  type: :array,
                  items: { "$ref": "#/components/schemas/ArticleIndex" }

          add_examples

          run_test!
        end
      end
    end
  end
end
# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
