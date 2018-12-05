require "rails_helper"

RSpec.describe "TagAdjustments", type: :request do
  let(:user)    { create(:user) }
  let(:user2)    { create(:user) }
  let(:tag) { create(:tag) }
  # let(:article) { create(:article, ) }

  describe "POST /tag_adjustments" do
    context "when signed in" do
      before do
        user.add_role(:tag_moderator, tag)
        user.add_role(:trusted)
        sign_in user
      end
      it "removes the tag" do
        article = Article.create!(user_id: user2.id, title: "test TEST", body_markdown: "Yo ho h o#{rand(100)}", tag_list: "#{tag.name}, yoyo, bobo", published: true)
        post "/tag_adjustments", params: {
          tag_adjustment: {
            tag_name: tag.name,
            article_id: article.id,
            reason_for_adjustment: "Test #{rand(100)}"
          },
        }
        expect(article.reload.tag_list.include?(tag.name)).to eq(false)
      end
      it "keeps the other tags" do
        article = Article.create!(user_id: user2.id, title: "test TEST", body_markdown: "Yo ho h o#{rand(100)}", tag_list: "#{tag.name}, yoyo, bobo", published: true)
        post "/tag_adjustments", params: {
          tag_adjustment: {
            tag_name: tag.name,
            article_id: article.id,
            reason_for_adjustment: "Test #{rand(100)}"
          },
          article_id: article.id
        }
        expect(article.reload.tag_list.include?("yoyo")).to eq(true)
      end
      it "removes the tag in a frontmatter context" do
        article = Article.create!(user_id: user2.id, body_markdown: "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: heyheyhey,#{tag.name}\n---\n\nHello")
        post "/tag_adjustments", params: {
          tag_adjustment: {
            tag_name: tag.name,
            article_id: article.id,
            reason_for_adjustment: "Test #{rand(100)}"
          },
        }
        expect(article.reload.tag_list.include?(tag.name)).to eq(false)
      end
      it "keeps the other tags in a frontmatter context" do
        article = Article.create!(user_id: user2.id, body_markdown: "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: heyheyhey,#{tag.name}\n---\n\nHello")
        post "/tag_adjustments", params: {
          tag_adjustment: {
            tag_name: tag.name,
            article_id: article.id,
            reason_for_adjustment: "Test #{rand(100)}"
          },
        }
        expect(article.reload.tag_list.include?("heyheyhey")).to eq(true)
      end
    end
  end
end
