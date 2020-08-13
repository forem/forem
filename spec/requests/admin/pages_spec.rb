require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/pages", type: :request do
  it_behaves_like "an InternalPolicy dependant request", Page do
    let(:request) { get "/admin/pages" }
  end
end
