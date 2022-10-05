require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "api/v1/reactions", type: :request do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:category) { "like" }
  let(:reactable) { create :article }
  let(:reaction) { reactable.reactions.create user: user, category: "like" }
  let(:result) { ReactionHandler::Result.new reaction: reaction }
  let(:user) { api_secret.user }

  before do
    user.add_role(:admin)

    result.category = category
    allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true)
    allow(ReactionHandler).to receive(:toggle).and_return(result)
  end

  path "/api/reactions/toggle" do
    describe "post to toggle reaction" do
      post("toggle reaction") do
        tags "reactions"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to toggle the user's reaction to a specified reactable (eg, Article, Comment, or User). For examples:
        * "Like"ing an Article will create a new "like" Reaction from the user for that Articles
        * "Like"ing that Article a second time will remove the "like" from the user
        DESCRIBE

        produces "application/json"
        parameter name: :category, in: :query, required: true, schema: {
          type: :string,
          enum: ReactionCategory.public
        }
        parameter name: :reactable_id, in: :query, required: true, schema: {
          type: :integer,
          format: :int32
        }
        parameter name: :reactable_type, in: :query, required: true, schema: {
          type: :string,
          enum: Reaction::REACTABLE_TYPES
        }

        let(:reactable_id) { reactable.id }
        let(:reactable_type) { "Article" }

        before do
          result.action = "create"
        end

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end
      end
    end
  end

  path "/api/reactions" do
    describe "post to create reaction" do
      post("create reaction") do
        tags "reactions"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to create a reaction to a specified reactable (eg, Article, Comment, or User). For examples:
        * "Like"ing an Article will create a new "like" Reaction from the user for that Articles
        * "Like"ing that Article a second time will return the previous "like"
        DESCRIBE

        produces "application/json"
        parameter name: :category, in: :query, required: true, schema: {
          type: :string,
          enum: ReactionCategory.public
        }
        parameter name: :reactable_id, in: :query, required: true, schema: {
          type: :integer,
          format: :int32
        }
        parameter name: :reactable_type, in: :query, required: true, schema: {
          type: :string,
          enum: Reaction::REACTABLE_TYPES
        }

        let(:reactable_id) { reactable.id }
        let(:reactable_type) { "Article" }

        before do
          result.action = "create"
        end

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
