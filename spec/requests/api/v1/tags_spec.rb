require "rails_helper"

RSpec.describe "Api::V1::Tags", type: :request do
  describe "GET /api/tags" do
    let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }

    before { allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true) }

    it "returns tags" do
      create(:tag, taggings_count: 10)

      get api_tags_path, headers: headers

      expect(response.parsed_body.size).to eq(1)
    end

    it "returns tags with the correct json representation" do
      badge = create(:badge)
      tag = create(:tag, taggings_count: 10)
      tag_with_badge = create(:tag, taggings_count: 5, badge: badge)

      get api_tags_path, headers: headers

      response_tag = response.parsed_body.first
      response_tag_with_badge = response.parsed_body.last
      expect_valid_json_body(response_tag, tag)
      expect_valid_json_body(response_tag_with_badge, tag_with_badge)
    end

    it "orders tags by taggings_count in a descending order" do
      tag = create(:tag, taggings_count: 10)
      other_tag = create(:tag, taggings_count: tag.taggings_count + 1)

      get api_tags_path, headers: headers

      expected_result = [other_tag.id, tag.id]
      expect(response.parsed_body.map { |t| t["id"] }).to eq(expected_result)
    end

    it "supports pagination" do
      create_list(:tag, 3)

      get api_tags_path, params: { page: 1, per_page: 2 }, headers: headers
      expect(response.parsed_body.length).to eq(2)

      get api_tags_path, params: { page: 2, per_page: 2 }, headers: headers
      expect(response.parsed_body.length).to eq(1)
    end

    it "respects API_PER_PAGE_MAX limit set in ENV variable" do
      allow(ApplicationConfig).to receive(:[]).and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("http://")
      allow(ApplicationConfig).to receive(:[]).with("API_PER_PAGE_MAX").and_return(2)

      create_list(:tag, 3)

      get api_tags_path, params: { per_page: 10 }, headers: headers
      expect(response.parsed_body.count).to eq(2)
    end

    it "sets the correct edge caching surrogate key for all tags" do
      tag = create(:tag, taggings_count: 10)

      get api_tags_path, headers: headers

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
