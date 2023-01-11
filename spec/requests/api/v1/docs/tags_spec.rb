require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::Tags" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }

  describe "GET /tags" do
    before do
      user.add_role(:admin)
    end

    path "/api/follows/tags" do
      get "Followed Tags" do
        tags "tags"
        description "This endpoint allows the client to retrieve a list of the tags they follow."
        operationId "getFollowedTags"
        produces "application/json"

        response "401", "Unauthorized" do
          let(:"api-key") { nil }
          add_examples

          run_test!
        end

        response "200", "A list of followed tags" do
          let(:"api-key") { api_secret.secret }
          schema  type: :array,
                  items: { "$ref": "#/components/schemas/FollowedTag" }
          add_examples

          run_test!
        end
      end
    end

    path "/api/tags" do
      get "Tags" do
        tags "tags"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve a list of tags that can be used to tag articles.
        It will return tags ordered by popularity.
        It supports pagination, each page will contain `10` tags by default.
        DESCRIBE
        operationId "getTags"
        produces "application/json"
        parameter "$ref": "#/components/parameters/pageParam"
        parameter "$ref": "#/components/parameters/perPageParam10to1000"

        response "200", "A list of tags" do
          let(:"api-key") { api_secret.secret }
          schema  type: :array,
                  items: { "$ref": "#/components/schemas/Tag" }

          add_examples

          run_test!
        end
      end
    end
  end
end
# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
