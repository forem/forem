require "rails_helper"

RSpec.describe "Tags", :proper_status do
  describe "GET /tags" do
    it "returns proper page and excludes tags with alias", :aggregate_failures do
      create(:tag, name: "ruby")
      create(:tag, name: "javascript", alias_for: "")
      create(:tag, name: "aliastag", alias_for: "ruby")

      get tags_path
      expect(response.body).to include("Tags", "ruby", "javascript")
      expect(response.body).not_to include("aliastag")
    end

    it "searches tags", :aggregate_failures do
      %w[ruby java javascript].each { |t| create(:tag, name: t) }

      get tags_path(q: "ruby")
      expect(response.body).to include("Search results for ruby", "ruby")
      expect(response.body).not_to include("javascript")

      get tags_path(q: "java")
      expect(response.body).to include("Search results for java", "java", "javascript")
      expect(response.body).not_to include("ruby")

      get tags_path(q: "yeet")
      expect(response.body).to include("No results match that query")
    end
  end

  describe "GET /tags/bulk" do
    it "returns a JSON representation of matching tags by tag_ids and tag_names", :aggregate_failures do
      tags = create_list(:tag, 3, taggings_count: 10)
      tag_names = tags.first(2).map(&:name)
      tag_ids = tags.last(2).map(&:id)

      get bulk_tags_path, params: { tag_names: tag_names, tag_ids: tag_ids }
      expect(response.parsed_body.pluck("id")).to match_array(tag_ids)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to match(%r{application/json; charset=utf-8}i)

      get bulk_tags_path, params: { tag_ids: tag_ids }
      expect(response.parsed_body.pluck("id")).to match_array(tag_ids)

      get bulk_tags_path, params: { tag_names: tag_names }
      expect(response.parsed_body.pluck("name")).to match_array(tag_names)
    end
  end

  describe "GET /tags/suggest" do
    it "returns a JSON representation of the top tags and preloads badges in a single query", :aggregate_failures do
      badged_tags = Array.new(2) { create(:tag, badge: create(:badge)) }
      create(:tag)

      badge_queries = []
      callback = lambda do |*, payload|
        badge_queries << payload[:sql] if payload[:sql].include?('FROM "badges"')
      end
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get suggest_tags_path
      end

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to match(%r{application/json; charset=utf-8}i)
      expect(badge_queries.size).to eq(1)
      expect(response.parsed_body.count { |t| t["badge"].present? }).to eq(2)

      response_tag = response.parsed_body.detect { |t| t["name"] == badged_tags.first.name }
      expect(response_tag).to include("rules_html", "short_summary", "bg_color_hex", "badge")
      expect(response_tag["badge"]).to have_key("badge_image")
    end
  end

  describe "GET /t/:tag/edit" do
    let(:tag)                  { create(:tag) }
    let(:another_tag)          { create(:tag) }
    let(:unauthorized_user)    { create(:user, :without_profile, profile_image: nil) }
    let(:tag_moderator)        { create(:user, :without_profile, profile_image: nil) }
    let(:super_admin)          { create(:user, :super_admin, :without_profile, profile_image: nil) }

    before do
      allow(Settings::General).to receive(:suggested_tags).and_return(%w[beginners javascript career])
    end

    it "does not allow not logged-in users" do
      get "/t/#{tag}/edit"
      expect(response).to redirect_to("/magic_links/new")
    end

    it "does not allow users who are not tag moderators" do
      sign_in unauthorized_user
      get "/t/#{tag}/edit"
      expect(response).to have_http_status(:not_found)
    end

    it "allows super admins" do
      sign_in super_admin
      get "/t/#{tag}/edit"
      expect(response.body).to include(I18n.t("views.tags.edit.help"))
    end

    context "when user is a tag moderator" do
      it "allows authorized tag moderators and forbids editing another tag", :aggregate_failures do
        tag_moderator.add_role(:tag_moderator, tag)
        sign_in tag_moderator

        get "/t/#{tag}/edit"
        expect(response.body).to include(I18n.t("views.tags.edit.help"))

        get "/t/#{another_tag}/edit"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "UPDATE /tags" do
    valid_params = { tag: { text_color_hex: "", bg_color_hex: "" } }
    let(:tag)                  { create(:tag) }
    let(:another_tag)          { create(:tag) }
    let(:unauthorized_user)    { create(:user, :without_profile, profile_image: nil) }
    let(:tag_moderator)        { create(:user, :without_profile, profile_image: nil) }
    let(:super_admin)          { create(:user, :super_admin, :without_profile, profile_image: nil) }

    it "does not allow not logged-in users" do
      patch "/tag/#{tag.id}"
      expect(response).to redirect_to("/magic_links/new")
    end

    it "does not allow unauthorized users" do
      sign_in unauthorized_user
      patch "/tag/#{tag.id}"
      expect(response).to have_http_status(:not_found)
    end

    it "allows super admins" do
      sign_in super_admin
      patch "/tag/#{tag.id}", params: valid_params
      expect(response).to redirect_to("/t/#{tag}/edit")
    end

    context "when user is a tag moderator" do
      before do
        tag_moderator.add_role(:tag_moderator, tag)
        sign_in tag_moderator
      end

      it "allows authorized tag moderators to update a tag and updates updated_at", :aggregate_failures do
        tag.update_column(:updated_at, 2.weeks.ago)
        patch "/tag/#{tag.id}", params: valid_params
        expect(response).to redirect_to("/t/#{tag}/edit")
        expect(tag.reload.updated_at).to be > 1.minute.ago

        patch("/tag/#{another_tag.id}", params: valid_params)
        expect(response).to have_http_status(:not_found)
      end

      it "displays proper error messages" do
        invalid_text_color_hex = "udjsadasfkdjsa"
        patch "/tag/#{tag.id}", params: {
          tag: { text_color_hex: invalid_text_color_hex, bg_color_hex: "" }
        }
        expect(response.body).to include("Text color hex is invalid")
      end
    end
  end
end
