require "rails_helper"

RSpec.describe "HtmlVariants", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id, approved: true) }

  before do
    sign_in user
  end

  describe "GET /html_variants" do
    it "rejects non-permissioned user" do
      expect { get "/html_variants" }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "accepts permissioned" do
      user.add_role(:super_admin)
      get "/html_variants"
      expect(response.body).to include("HTML Variants")
    end
  end

  describe "GET /html_variants/new" do
    it "rejects non-permissioned user" do
      expect { get "/html_variants/new" }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "accepts permissioned" do
      user.add_role(:super_admin)
      get "/html_variants/new"
      expect(response.body).to include("<form")
    end
  end

  describe "GET /html_variants/:id/edit" do
    it "rejects non-permissioned user" do
      html_variant = create(:html_variant)
      expect { get "/html_variants/#{html_variant.id}/edit" }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "accepts permissioned" do
      user.add_role(:super_admin)
      html_variant = create(:html_variant)
      get "/html_variants/#{html_variant.id}/edit"
      expect(response.body).to include("<form")
    end
  end

  describe "Post /html_variants" do
    it "rejects non-permissioned user" do
      expect { post "/html_variants" }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "creates" do
      user.add_role(:super_admin)
      post "/html_variants", params: {
        html_variant: {
          name: "New post",
          html: "Yo ho ho#{rand(100)}", tag_list: "yoyo",
          published: true,
          group: "article_show_sidebar_cta"
        }
      }
      expect(HtmlVariant.all.size).to eq(1)
    end

    it "does not create with invalid params" do
      user.add_role(:super_admin)
      post "/html_variants", params: {
        html_variant: {
          # name: NOTHING HERE
          html: "Yo ho ho#{rand(100)}", tag_list: "yoyo",
          published: true
        }
      }
      expect(HtmlVariant.all.size).to eq(0)
    end
  end

  describe "Put /html_variants" do
    it "rejects non-permissioned user" do
      expect { post "/html_variants" }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "updates when appropriate" do
      user.add_role(:super_admin)
      html_variant = create(:html_variant)
      new_html = "Yo ho ho#{rand(100)}"
      put "/html_variants/#{html_variant.id}", params: {
        html_variant: {
          html: new_html
        }
      }
      expect(html_variant.reload.html).to eq(new_html)
    end

    it "does not create with invalid params" do
      user.add_role(:super_admin)
      html_variant = create(:html_variant, approved: true, published: true)
      new_html = "Yo ho ho#{rand(100)}"
      put "/html_variants/#{html_variant.id}", params: {
        html_variant: {
          html: new_html
        }
      }
      expect(html_variant.reload.html).not_to eq(new_html)
    end
  end
end
