require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/internal/comments", type: :request do
  it_behaves_like "an InternalPolicy dependant request", Comment do
    let(:request) { get "/internal/comments" }
  end
end
