require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::Readinglist", appmap: false do
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
        This endpoint allows the client to retrieve a list of articles that were saved to a Users readinglist.
        It supports pagination, each page will contain `30` articles by default
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
