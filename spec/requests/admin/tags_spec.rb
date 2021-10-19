require "rails_helper"

RSpec.describe "/admin/content_manager/tags", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:tag)         { create(:tag) }
  let(:badge)       { create(:badge) }
  let(:user)        { create(:user) }

  let(:params) do
    {
      name: "WWW", supported: true, requires_approval: true,
      wiki_body_markdown: "## In here you'll see WWW posts",
      short_summary: "Everything WWW related ", rules_markdown: "## NO SPAM",
      submission_template: "# <TITLE>\n\n<ARTICLE_BODY>",
      pretty_name: "dubdubdub", bg_color_hex: "#333333",
      text_color_hex: "#ffffff", badge_id: badge.id,
      social_preview_template: "article"
    }
  end
  let(:post_resource) { post admin_tags_path, params: { tag: params } }
  let(:put_resource) { put admin_tag_path(tag.id), params: { tag: params } }

  before do
    sign_in super_admin
  end

  describe "GET /admin/content_manager/tags" do
    it "responds with 200 OK" do
      get admin_tags_path
      expect(response.status).to eq 200
    end
  end

  describe "GET /admin/content_manager/tags/:id" do
    it "responds with 200 OK" do
      get edit_admin_tag_path(tag.id)
      expect(response.status).to eq 200
    end
  end

  describe "POST /admin/content_manager/tags" do
    it "creates a new tag" do
      expect do
        post_resource
      end.to change { Tag.all.count }.by(1)
      expect(response.body).to redirect_to edit_admin_tag_path(Tag.last)
    end
  end

  describe "PUT /admin/content_manager/tags" do
    it "updates Tag" do
      put_resource
      tag.reload
      expect(tag.requires_approval).to eq(params[:requires_approval])
      expect(tag.wiki_body_markdown).to eq(params[:wiki_body_markdown])
      expect(tag.short_summary).to eq(params[:short_summary])
      expect(tag.rules_markdown).to eq(params[:rules_markdown])
      expect(tag.submission_template).to eq(params[:submission_template])
      expect(tag.pretty_name).to eq(params[:pretty_name])
      expect(tag.bg_color_hex).to eq(params[:bg_color_hex])
      expect(tag.text_color_hex).to eq(params[:text_color_hex])
    end

    it "updates posts when making a tag an alias for another tag" do
      create(:tag, name: "rails")
      article1 = create(:article, tags: "ruby, ror")
      article2 = create(:article, tags: "ror, webdev")
      alias_tag = Tag.find_by(name: "ror")

      sidekiq_perform_enqueued_jobs do
        put admin_tag_path(alias_tag), params: { tag: { alias_for: "rails" } }
      end

      expect(article1.reload.cached_tag_list).to eq "ruby, rails"
      expect(article2.reload.cached_tag_list).to eq "rails, webdev"
    end
  end
end
