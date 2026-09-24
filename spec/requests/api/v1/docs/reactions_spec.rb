require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "api/v1/reactions" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:category) { "like" }
  let(:reactable) { create(:article) }
  let(:reaction) { reactable.reactions.create user: user, category: "like" }
  let(:result) { ReactionHandler::Result.new reaction: reaction }
  let(:user) { api_secret.user }

  before do
    user.add_role(:admin)

    result.category = category
    allow(ReactionHandler).to receive(:toggle).and_return(result)
  end

  path "/api/reactions/toggle" do
    describe "post to toggle reaction" do
      post("toggle reaction") do
        tags "reactions"
        description(<<-DESCRIBE.strip)
        Toggle a reaction on a target resource (Article, Comment, or User) on behalf of the authenticated user.

        ### Toggle Logic:
        - **First Request**: Creates a new reaction of the specified category on the reactable target.
        - **Second Request (with same parameters)**: Deletes the existing reaction.
        - Particularly useful for simple, interactive UI buttons like "Like", "Unicorn", or "Save" where clicking toggles the active state.
        DESCRIBE

        produces "application/json"
        parameter name: :category, in: :query, required: true,
                  description: "The type of reaction (e.g. `like` for standard likes, `unicorn` for outstanding posts, `save` for bookmarking to the reading list).",
                  schema: {
                    type: :string,
                    enum: ReactionCategory.public
                  }
        parameter name: :reactable_id, in: :query, required: true,
                  description: "The unique numerical ID of the target resource (Article, Comment, or User) being reacted to.",
                  schema: {
                    type: :integer,
                    format: :int32
                  }
        parameter name: :reactable_type, in: :query, required: true,
                  description: "The class name of the target resource being reacted to (e.g. `Article`, `Comment`, `User`).",
                  schema: {
                    type: :string,
                    enum: Reaction::REACTABLE_TYPES
                  }

        let(:reactable_id) { reactable.id }
        let(:reactable_type) { "Article" }

        before do
          result.action = "create"
        end

        # rubocop:disable RSpec/RepeatedExampleGroupDescription
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
        Create a reaction on a target resource (Article, Comment, or User) on behalf of the authenticated user.

        ### Usage Details:
        - Unlike the toggle endpoint, this endpoint is idempotent: multiple requests to react with the same category to the same target will return the existing reaction without deleting it.
        DESCRIBE

        produces "application/json"
        parameter name: :category, in: :query, required: true,
                  description: "The type of reaction (e.g. `like` for standard likes, `unicorn` for outstanding posts, `save` for bookmarking to the reading list).",
                  schema: {
                    type: :string,
                    enum: ReactionCategory.public
                  }
        parameter name: :reactable_id, in: :query, required: true,
                  description: "The unique numerical ID of the target resource (Article, Comment, or User) being reacted to.",
                  schema: {
                    type: :integer,
                    format: :int32
                  }
        parameter name: :reactable_type, in: :query, required: true,
                  description: "The class name of the target resource being reacted to (e.g. `Article`, `Comment`, `User`).",
                  schema: {
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
