require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/internal/articles", type: :request do
  it_behaves_like "an InternalPolicy dependant request", Article do
    let(:request) { get "/internal/articles" }
  end
end
