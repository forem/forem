require "rails_helper"

RSpec.describe "Articles", type: :request do
  describe "default subforem_id assignment" do
    let(:user) { create(:user) }
    let(:default_subforem) { create(:subforem, domain: "default.com") }

    before do
      sign_in user
      RequestStore.store[:default_subforem_id] = default_subforem.id
    end

    after do
      RequestStore.store[:default_subforem_id] = nil
    end

    it "automatically assigns default subforem_id when creating an article" do
      expect do
        post "/articles", params: {
          article: {
            title: "Test Article",
            body_markdown: "Test content",
            subforem_id: nil
          }
        }
      end.to change(Article, :count).by(1)

      article = Article.last
      expect(article.subforem_id).to eq(default_subforem.id)
    end

    it "does not override explicitly set subforem_id" do
      other_subforem = create(:subforem, domain: "other.com")

      expect do
        post "/articles", params: {
          article: {
            title: "Test Article",
            body_markdown: "Test content",
            subforem_id: other_subforem.id
          }
        }
      end.to change(Article, :count).by(1)

      article = Article.last
      expect(article.subforem_id).to eq(other_subforem.id)
    end
  end
end
