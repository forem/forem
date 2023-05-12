require "rails_helper"

RSpec.describe "Api::V1::AudienceSegments" do
  let(:v1_headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }

  let(:api_secret) { create(:api_secret) }
  let(:admin) { api_secret.user }
  let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }

  before do
    admin.add_role(:admin)
  end

  shared_examples "an admin-only protected resource" do
    context "when no API secret is provided" do
      let(:headers) { v1_headers }

      it "returns unauthorized" do
        make_request
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when the authenticated user is not an admin" do
      let(:regular_api_secret) { create(:api_secret) }
      let(:headers) { v1_headers.merge({ "api-key" => regular_api_secret.secret }) }

      it "returns unauthorized" do
        make_request
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/segments" do
    it_behaves_like "an admin-only protected resource" do
      subject(:make_request) { post api_segments_path, headers: headers }
    end

    it "creates a new manual audience segment" do
      post api_segments_path, headers: headers

      expect(response).to have_http_status(:created)
      expect(response.media_type).to eq("application/json")

      segment = AudienceSegment.last
      expect(segment.manual?).to be(true)
      expect(response.parsed_body).to include(
        "id" => segment.id,
        "type_of" => "manual",
      )
    end
  end

  describe "PUT /api/segments/:id/add_users" do
    let(:segment) { AudienceSegment.create!(type_of: "manual") }
    let(:users) { create_list(:user, 3) }

    it_behaves_like "an admin-only protected resource" do
      subject(:make_request) { put add_users_api_segment_path(segment.id), headers: headers }
    end

    it "adds the provided users if it is a manual audience segment" do
      user_ids = users.map(&:id)
      put add_users_api_segment_path(segment.id), params: { user_ids: user_ids }, headers: headers, as: :json

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("application/json")

      expect(segment.users).to match_array(users)

      data = response.parsed_body
      expect(data["succeeded"]).to match_array(user_ids)
      expect(data["failed"]).to be_empty
    end

    it "returns user ids that failed to be added" do
      user_ids = users.map(&:id)
      fake_user_ids = [999_999, 777_777]
      params = { user_ids: user_ids + fake_user_ids }
      put add_users_api_segment_path(segment.id), params: params, headers: headers, as: :json

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("application/json")

      expect(segment.users).to match_array(users)

      data = response.parsed_body
      expect(data["succeeded"]).to match_array(user_ids)
      expect(data["failed"]).to match_array(fake_user_ids)
    end

    it "handles empty or missing user_ids" do
      put add_users_api_segment_path(segment.id), headers: headers
      expect(response).to have_http_status(:unprocessable_entity)

      put add_users_api_segment_path(segment.id), params: { user_ids: [] }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PUT /api/segments/:id/remove_users" do
    let(:segment) { AudienceSegment.create!(type_of: "manual") }
    let(:users) { create_list(:user, 3) }
    let(:retained_users) { create_list(:user, 3) }
    let(:users_not_in_segment) { create_list(:user, 3) }

    before do
      segment.users << users
      segment.users << retained_users
    end

    it_behaves_like "an admin-only protected resource" do
      subject(:make_request) { put remove_users_api_segment_path(segment.id), headers: headers }
    end

    it "removes only the provided users if they are part of the manual audience segment" do
      user_ids = users.map(&:id)
      put remove_users_api_segment_path(segment.id), params: { user_ids: user_ids }, headers: headers, as: :json

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("application/json")

      expect(segment.users).to match_array(retained_users)

      data = response.parsed_body
      expect(data["succeeded"]).to match_array(user_ids)
      expect(data["failed"]).to be_empty
    end

    it "returns user ids that failed to be removed" do
      user_ids = users.map(&:id)
      ids_to_fail = [*users_not_in_segment.map(&:id), 123_456]
      params = { user_ids: user_ids + ids_to_fail }
      put remove_users_api_segment_path(segment.id), params: params, headers: headers, as: :json

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("application/json")

      expect(segment.users).to match_array(retained_users)

      data = response.parsed_body
      expect(data["succeeded"]).to match_array(user_ids)
      expect(data["failed"]).to match_array(ids_to_fail)
    end

    it "handles empty or missing user_ids" do
      put remove_users_api_segment_path(segment.id), headers: headers
      expect(response).to have_http_status(:unprocessable_entity)

      put remove_users_api_segment_path(segment.id), params: { user_ids: [] }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
