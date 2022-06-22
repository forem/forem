require "rails_helper"

RSpec.describe "Api::V0::Tags", type: :request do
  describe "GET /api/tags" do
    let(:api_secret) { create(:api_secret) }
    let(:v1_headers) { { "api-key" => api_secret.secret, "Accept" => "application/vnd.forem.api-v1+json" } }

    before { allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true) }

    context "when unauthenticated" do
      it "returns unauthorized" do
        get api_tags_path, headers: { "Accept" => "application/vnd.forem.api-v1+json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when unauthorized" do
      it "returns unauthorized" do
        get api_tags_path, headers: v1_headers.merge({ "api-key" => "invalid api key" })
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it "returns tags" do
      create(:tag, taggings_count: 10)

      get api_tags_path, headers: v1_headers

      expect(response.parsed_body.size).to eq(1)
    end

    it "returns tags with the correct json representation" do
      badge = create(:badge)
      tag = create(:tag, taggings_count: 10)
      tag_with_badge = create(:tag, taggings_count: 5, badge: badge)

      get api_tags_path, headers: v1_headers

      response_tag = response.parsed_body.first
      response_tag_with_badge = response.parsed_body.last
      expect_valid_json_body(response_tag, tag)
      expect_valid_json_body(response_tag_with_badge, tag_with_badge)
    end

    it "orders tags by taggings_count in a descending order" do
      tag = create(:tag, taggings_count: 10)
      other_tag = create(:tag, taggings_count: tag.taggings_count + 1)

      get api_tags_path, headers: v1_headers

      expected_result = [other_tag.id, tag.id]
      expect(response.parsed_body.map { |t| t["id"] }).to eq(expected_result)
    end

    it "supports pagination" do
      create_list(:tag, 3)

      get api_tags_path, params: { page: 1, per_page: 2 }, headers: v1_headers
      expect(response.parsed_body.length).to eq(2)

      get api_tags_path, params: { page: 2, per_page: 2 }, headers: v1_headers
      expect(response.parsed_body.length).to eq(1)
    end

    it "sets the correct edge caching surrogate key for all tags" do
      tag = create(:tag, taggings_count: 10)

      get api_tags_path, headers: v1_headers

      expected_key = ["tags", tag.record_key].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end
  end

  private

  def expect_valid_json_body(body, tag)
    expect(body.keys).to match_array(%w[id name bg_color_hex text_color_hex])
    expect(body["id"]).to eq(tag.id)
    expect(body["name"]).to eq(tag.name)
    expect(body["bg_color_hex"]).to eq(tag.bg_color_hex)
    expect(body["text_color_hex"]).to eq(tag.text_color_hex)
  end
end
