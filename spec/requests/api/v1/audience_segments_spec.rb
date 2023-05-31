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

  shared_examples "an endpoint for only manual audience segments" do
    it "returns not found if the segment is automatic" do
      segment.update!(type_of: "trusted")
      make_request
      expect(response).to have_http_status(:not_found)
    end

    it "returns not found if the segment has been deleted" do
      segment.destroy
      make_request
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/segments" do
    subject(:make_request) { get api_segments_path, headers: headers }

    let(:first_manual_segment) { AudienceSegment.create!(type_of: "manual") }
    let(:second_manual_segment) { AudienceSegment.create!(type_of: "manual") }
    let(:automatic_segment) { AudienceSegment.create!(type_of: "trusted") }
    let(:users) { create_list(:user, 3) }

    it_behaves_like "an admin-only protected resource"

    it "returns only manual segments including their user counts" do
      first_manual_segment.users << users
      expected_data = [
        hash_including(
          "id" => first_manual_segment.id,
          "type_of" => "manual",
          "user_count" => 3,
        ),
        hash_including(
          "id" => second_manual_segment.id,
          "type_of" => "manual",
          "user_count" => 0,
        ),
      ]
      excluded_data = hash_including("id" => automatic_segment.id)

      make_request

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("application/json")

      expect(response.parsed_body).to include(*expected_data)
      expect(response.parsed_body).not_to include(excluded_data)
    end

    it "supports pagination" do
      5.times.each { AudienceSegment.create!(type_of: :manual) }

      get api_segments_path, params: { page: 1, per_page: 3 }, headers: headers
      expect(response.parsed_body.length).to eq(3)
      get api_segments_path, params: { page: 2, per_page: 4 }, headers: headers
      expect(response.parsed_body.length).to eq(1)
    end

    it "respects API_PER_PAGE_MAX env variable limit" do
      5.times.each { AudienceSegment.create!(type_of: :manual) }

      allow(ApplicationConfig).to receive(:[]).and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("http://")
      allow(ApplicationConfig).to receive(:[]).with("API_PER_PAGE_MAX").and_return(3)

      get api_segments_path, params: { per_page: 10 }, headers: headers
      expect(response.parsed_body.length).to eq(3)
    end
  end

  describe "GET /api/segments/:id" do
    subject(:make_request) { get api_segment_path(segment.id), headers: headers }

    let(:segment) { AudienceSegment.create!(type_of: "manual") }
    let(:users) { create_list(:user, 3) }

    it_behaves_like "an admin-only protected resource"

    it_behaves_like "an endpoint for only manual audience segments"

    it "returns the segment including its user count" do
      segment.users << users

      make_request

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("application/json")
      expect(response.parsed_body).to include(
        "id" => segment.id,
        "type_of" => "manual",
        "user_count" => 3,
      )
    end
  end

  describe "POST /api/segments" do
    subject(:make_request) { post api_segments_path, headers: headers }

    it_behaves_like "an admin-only protected resource"

    it "creates a new manual audience segment" do
      make_request

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

  describe "GET /api/segments/:id/users" do
    subject(:make_request) { get users_api_segment_path(segment.id), headers: headers }

    let(:segment) { AudienceSegment.create!(type_of: "manual") }
    let(:users) { create_list(:user, 5) }

    it_behaves_like "an admin-only protected resource"

    it_behaves_like "an endpoint for only manual audience segments"

    it "returns a list of users in the segment" do
      segment.users << users

      expected_data = users.map do |user|
        hash_including(
          "id" => user.id,
          "username" => user.username,
          "name" => user.name,
          "twitter_username" => user.twitter_username,
          "github_username" => user.github_username,
          "summary" => user.profile.summary,
          "location" => user.profile.location,
          "website_url" => user.profile.website_url,
        )
      end

      make_request

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("application/json")
      expect(response.parsed_body).to match_array(expected_data)
    end

    it "supports pagination" do
      segment.users << users

      get users_api_segment_path(segment.id), params: { page: 1, per_page: 3 }, headers: headers
      expect(response.parsed_body.length).to eq(3)
      get users_api_segment_path(segment.id), params: { page: 2, per_page: 4 }, headers: headers
      expect(response.parsed_body.length).to eq(1)
    end

    it "respects API_PER_PAGE_MAX env variable limit" do
      segment.users << users

      allow(ApplicationConfig).to receive(:[]).and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("http://")
      allow(ApplicationConfig).to receive(:[]).with("API_PER_PAGE_MAX").and_return(3)

      get users_api_segment_path(segment.id), params: { per_page: 5 }, headers: headers
      expect(response.parsed_body.length).to eq(3)
    end
  end

  describe "PUT /api/segments/:id/add_users" do
    subject(:make_request) do
      put add_users_api_segment_path(segment.id), params: { user_ids: user_ids }, headers: headers, as: :json
    end

    let(:segment) { AudienceSegment.create!(type_of: "manual") }
    let(:users) { create_list(:user, 3) }
    let(:user_ids) { users.map(&:id) }

    it_behaves_like "an admin-only protected resource"

    it_behaves_like "an endpoint for only manual audience segments"

    it "adds the provided users" do
      make_request

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("application/json")

      expect(segment.users).to match_array(users)

      data = response.parsed_body
      expect(data["succeeded"]).to match_array(user_ids)
      expect(data["failed"]).to be_empty
    end

    it "returns user ids that failed to be added" do
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

    it "handles empty, missing or too large user_ids" do
      put add_users_api_segment_path(segment.id), headers: headers
      expect(response).to have_http_status(:unprocessable_entity)

      put add_users_api_segment_path(segment.id), params: { user_ids: [] }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)

      params = { user_ids: (1..10_100).to_a }
      put add_users_api_segment_path(segment.id), params: params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PUT /api/segments/:id/remove_users" do
    subject(:make_request) do
      put remove_users_api_segment_path(segment.id), params: { user_ids: user_ids }, headers: headers, as: :json
    end

    let(:segment) { AudienceSegment.create!(type_of: "manual") }
    let(:users) { create_list(:user, 3) }
    let(:user_ids) { users.map(&:id) }
    let(:retained_users) { create_list(:user, 3) }
    let(:users_not_in_segment) { create_list(:user, 3) }

    before do
      segment.users << users
      segment.users << retained_users
    end

    it_behaves_like "an admin-only protected resource"

    it_behaves_like "an endpoint for only manual audience segments"

    it "removes only the provided users if they are part of the segment" do
      make_request

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("application/json")

      expect(segment.users).to match_array(retained_users)

      data = response.parsed_body
      expect(data["succeeded"]).to match_array(user_ids)
      expect(data["failed"]).to be_empty
    end

    it "returns user ids that failed to be removed" do
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

    it "handles empty, missing or too large user_ids" do
      put remove_users_api_segment_path(segment.id), headers: headers
      expect(response).to have_http_status(:unprocessable_entity)

      put remove_users_api_segment_path(segment.id), params: { user_ids: [] }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)

      params = { user_ids: (1..10_100).to_a }
      put remove_users_api_segment_path(segment.id), params: params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/segments/:id" do
    subject(:make_request) { delete api_segment_path(segment.id), headers: headers }

    let(:segment) { AudienceSegment.create!(type_of: "manual") }
    let(:users) { create_list(:user, 3) }
    let(:billboard) { create(:display_ad, published: true, approved: true, type_of: "community") }

    it_behaves_like "an admin-only protected resource"

    it_behaves_like "an endpoint for only manual audience segments"

    it "destroys the segment and cleans up its list of users" do
      segment.users << users

      make_request

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("application/json")
      expect(AudienceSegment.exists?(segment.id)).to be(false)
      expect(SegmentedUser.where(audience_segment_id: segment.id)).to be_empty
    end

    it "does not destroy the segment or its user list if it is associated with a billboard" do
      segment.users << users
      billboard.update!(audience_segment: segment)

      make_request

      expect(response).to have_http_status(:conflict)
      expect(response.media_type).to eq("application/json")
      expect(response.parsed_body.keys).to include("error")
      expect(segment.reload.users).to match_array(users)
    end
  end
end
