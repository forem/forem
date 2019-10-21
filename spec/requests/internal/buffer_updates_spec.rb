require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/internal/buffer_updates", type: :request do
  it_behaves_like "an InternalPolicy dependant request", BufferUpdate do
    let(:request) { post "/internal/buffer_updates" }
  end
end
