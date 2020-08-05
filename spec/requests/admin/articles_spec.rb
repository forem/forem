require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/articles", type: :request do
  it_behaves_like "an InternalPolicy dependant request", Article do
    let(:request) { get "/admin/articles" }
  end
end
