require "rails_helper"

RSpec.describe "Api::V0::Tags", type: :request do
  describe "GET /api/tags" do
    it "returns tags" do
      create(:tag, taggings_count: 10)

      get api_tags_path

      expect(response.parsed_body.size).to eq(1)
    end

    it "returns tags with the correct json representation" do
      badge = create(:badge)
      tag = create(:tag, taggings_count: 10)
      tag_with_badge = create(:tag, taggings_count: 5, badge: badge)

      get api_tags_path

      response_tag = response.parsed_body.first
      response_tag_with_badge = response.parsed_body.last
      expect_valid_json_body(response_tag, tag)
      expect_valid_json_body(response_tag_with_badge, tag_with_badge)

      expect(response_tag["badge"]["badge_image"]).to be_nil
      expect(response_tag_with_badge["badge"]["badge_image"]["url"]).to eq(tag_with_badge.badge.badge_image.url)
    end

    it "orders tags by taggings_count in a descending order" do
      tag = create(:tag, taggings_count: 10)
      other_tag = create(:tag, taggings_count: tag.taggings_count + 1)

      get api_tags_path

      expected_result = [other_tag.id, tag.id]
      expect(response.parsed_body.map { |t| t["id"] }).to eq(expected_result)
    end

    it "finds tags from array of tag_ids" do
      tags = create_list(:tag, 10, taggings_count: 10)
      tag_ids = tags.sample(4).map(&:id)

      get api_tags_path, params: { tag_ids: tag_ids }

      expect(response.parsed_body.map { |t| t["id"] }).to match_array(tag_ids)
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

  private

  def expect_valid_json_body(body, tag)
    expect(body.keys).to match_array(%w[id name bg_color_hex text_color_hex short_summary badge])
    expect(body["id"]).to eq(tag.id)
    expect(body["name"]).to eq(tag.name)
    expect(body["bg_color_hex"]).to eq(tag.bg_color_hex)
    expect(body["text_color_hex"]).to eq(tag.text_color_hex)
    expect(body["short_summary"]).to eq(tag.short_summary)
    expect(body).to have_key("badge")
    expect(body["badge"]).to have_key("badge_image")
  end
end
