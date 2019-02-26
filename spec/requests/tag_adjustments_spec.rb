require "rails_helper"

RSpec.describe "TagAdjustments", type: :request do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:tag) { create(:tag) }
  let(:tag_adjustment_params) do
    {
      tag_name: tag.name,
      article_id: article.id,
      reason_for_adjustment: "Test #{rand(100)}"
    }
  end

  describe "POST /tag_adjustments" do
    before do
      user.add_role(:tag_moderator, tag)
      user.add_role(:trusted)
      sign_in user
      post "/tag_adjustments", params: {
        tag_adjustment: tag_adjustment_params,
        article_id: article.id
      }
    end

    context "when an article doesn't use front matter" do
      let(:article) { Article.create(user: user, title: "something", body_markdown: "blah blah #{rand(100)}", tag_list: "#{tag.name}, yoyo, bobo", published: true) }

      it "removes the tag" do
        expect(article.reload.tag_list.include?(tag.name)).to be false
      end

      it "keeps the other tags" do
        expect(article.reload.tag_list.include?("yoyo")).to be true
      end
    end

    context "when an article uses front matter" do
      let(:article) { create(:article, user: user, body_markdown: "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: heyheyhey,#{tag.name}\n---\n\nHello") }

      it "removes the tag" do
        expect(article.reload.tag_list.include?(tag.name)).to be false
      end

      it "keeps the other tags" do
        expect(article.reload.tag_list.include?("heyheyhey")).to be true
      end
    end
  end
end
