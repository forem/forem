require "rails_helper"

RSpec.describe "Api::V0::Tags", type: :request do
  describe "GET /api/tags" do
    it "returns tags" do
      create(:tag, taggings_count: 10)

      get api_tags_path

      expect(response.parsed_body.size).to eq(1)
    end

    it "returns tags with the correct json representation" do
      tag = create(:tag, taggings_count: 10)

      get api_tags_path

      response_tag = response.parsed_body.first
      expect(response_tag.keys).to match_array(%w[id name bg_color_hex text_color_hex])
      expect(response_tag["id"]).to eq(tag.id)
      expect(response_tag["name"]).to eq(tag.name)
      expect(response_tag["bg_color_hex"]).to eq(tag.bg_color_hex)
      expect(response_tag["text_color_hex"]).to eq(tag.text_color_hex)
    end

    it "orders tags by taggings_count in a descending order" do
      tag = create(:tag, taggings_count: 10)
      other_tag = create(:tag, taggings_count: tag.taggings_count + 1)

      get api_tags_path

      expected_result = [other_tag.id, tag.id]
      expect(response.parsed_body.map { |t| t["id"] }).to eq(expected_result)
    end

    it "supports pagination" do
      create_list(:tag, 3)

      get api_tags_path, params: { page: 1, per_page: 2 }
      expect(response.parsed_body.length).to eq(2)

      get api_tags_path, params: { page: 2, per_page: 2 }
      expect(response.parsed_body.length).to eq(1)
    end

    it "sets the correct edge caching surrogate key for all tags" do
      tag = create(:tag, taggings_count: 10)

      get api_tags_path

      expected_key = ["tags", tag.record_key].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end
  end

  describe "GET /api/tags/me" do
    let(:tags) { create_list(:tag, 5) }
    let(:user) { create(:user) }
    let(:api_token) { create(:api_secret, user: user) }

    before do
      followed_tags = tags.first(3)
      followed_tags.each { |tag| user.follow(tag) }
    end

    context "with invalid authentication" do
      it "returns unauthorized" do
        get me_api_tags_path, headers: { "api-key" => "askjdfhlk" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with valid authentication" do
      it "returns only the tags followed by the user" do
        get me_api_tags_path, headers: { "api-key" => api_token.secret }

        expect(response.body).to eq tags.first(3).to_json
      end
    end
  end
end
