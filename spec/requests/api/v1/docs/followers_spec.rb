require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::Followers" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }
  let(:follower1) { create(:user) }
  let(:follower2) { create(:user) }

  before do
    follower1.follow(user)
    follower2.follow(user)
    user.reload
  end

  describe "GET /followers/users" do
    path "/api/followers/users" do
      get "Followers" do
      end
    end
  end
end

# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable RSpec/VariableName