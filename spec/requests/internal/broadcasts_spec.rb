require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/internal/Broadcasts", type: :request do
  it_behaves_like "an InternalPolicy dependant request", Broadcast do
    let(:request) { get "/internal/broadcasts" }
  end
end
