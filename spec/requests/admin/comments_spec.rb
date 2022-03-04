require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/content_manager/comments", type: :request do
  it_behaves_like "an InternalPolicy dependant request", Comment do
    let(:request) { get admin_comments_path }
  end
end
