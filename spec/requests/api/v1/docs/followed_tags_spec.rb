require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::FollowedTags" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }
  let(:tag1) { create(:tag) }
  let(:tag2) { create(:tag) }

  let(:tag1_json) { { id: tag1.id, name: tag1.name, points: 1.0 } }
  let(:tag2_json) { { id: tag2.id, name: tag2.name, points: 1.0 } }

  before do
    [tag1, tag2].each { |tag| user.follow(tag) }
  end

  describe "GET /follows/tags" do
    path "/api/follows/tags" do
      get "Followed Tags" do
        tags "followed_tags", "tags"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve a list of the tags they follow.
        DESCRIBE
        operationId "getFollowedTags"
        produces "application/json"

        response "401", "unauthorized" do
          let(:"api-key") { nil }
          add_examples

          run_test!
        end

        response "200", "A List of followed tags" do
          let(:"api-key") { api_secret.secret }
          schema  type: :array,
                  items: { "$ref": "#/components/schemas/FollowedTag" }
          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable RSpec/VariableName
