require "rails_helper"

RSpec.describe "TagAdjustments", type: :request do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:tag) { create(:tag) }
  let(:tag_adjustment_params) do
    {
      tag_name: tag.name,
      article_id: article.id,
      adjustment_type: "removal"
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
      let(:article) do
        Article.create(
          user: user, title: "something", body_markdown: "blah blah #{rand(100)}",
          tag_list: "#{tag.name}, yoyo, bobo", published: true
        )
      end

      it "removes the tag" do
        expect(article.reload.tag_list.include?(tag.name)).to be false
      end

      it "keeps the other tags" do
        expect(article.reload.tag_list.include?("yoyo")).to be true
      end
    end

    context "when an article uses front matter" do
      let(:article) do
        body = "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: heyheyhey,#{tag.name}\n---\n\nHello"
        create(:article, user: user, body_markdown: body)
      end

      it "removes the tag" do
        expect(article.reload.tag_list.include?(tag.name)).to be false
      end

      it "keeps the other tags" do
        expect(article.reload.tag_list.include?("heyheyhey")).to be true
      end
    end
  end

  describe "POST /tag_adjustments with adjustment_type addition" do
    before do
      tag_adjustment_params[:adjustment_type] = "addition"
      user.add_role(:tag_moderator, tag)
      user.add_role(:trusted)
      sign_in user
      post "/tag_adjustments", params: {
        tag_adjustment: tag_adjustment_params,
        article_id: article.id
      }
    end

    context "when an article doesn't use front matter" do
      let(:article) do
        Article.create(
          user: user, title: "something", body_markdown: "blah blah #{rand(100)}",
          tag_list: "yoyo, bobo", published: true
        )
      end

      it "adds the tag" do
        expect(article.reload.tag_list.include?(tag.name)).to be true
      end

      it "keeps the other tags" do
        expect(article.reload.tag_list.include?("yoyo")).to be true
      end
    end

    context "when an article uses front matter" do
      let(:article) do
        body_markdown = "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: heyheyhey\n---\n\nHello"
        create(:article, user: user, body_markdown: body_markdown)
      end

      it "adds the tag" do
        expect(article.reload.tag_list.include?(tag.name)).to be true
      end

      it "keeps the other tags" do
        expect(article.reload.tag_list.include?("heyheyhey")).to be true
      end
    end
  end

  describe "DELETE /tag_adjustments/:id" do
    let(:tag_adjustment) { create(:tag_adjustment, article_id: article.id, user: user, tag: tag) }

    before do
      user.add_role(:admin)
      user.add_role(:trusted)
      tag_adjustment
      sign_in user
    end

    context "when an article doesn't use front matter" do
      let(:article) do
        Article.create(user: user, title: "something", body_markdown: "blah blah #{rand(100)}",
                       tag_list: "#{tag.name}, yoyo, bobo", published: true)
      end

      it "adds the tag back in" do
        delete "/tag_adjustments/#{tag_adjustment.id}", params: {
          id: tag_adjustment.id
        }
        expect(article.tag_list).to include tag.name
      end
    end

    context "when an article uses front matter" do
      let(:article) do
        body = "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: heyheyhey,#{tag.name}\n---\n\nHello"
        create(:article, user: user, body_markdown: body)
      end

      it "adds the tag back in" do
        delete "/tag_adjustments/#{tag_adjustment.id}", params: {
          id: tag_adjustment.id
        }
        expect(article.tag_list).to include tag.name
      end
    end
  end

  describe "DELETE /tag_adjustments/:id with adjustment_type addition" do
    let(:tag_adjustment) do
      create(:tag_adjustment, article_id: article.id, user: user, tag: tag, adjustment_type: "addition")
    end

    before do
      user.add_role(:admin)
      user.add_role(:trusted)
      tag_adjustment
      sign_in user
    end

    context "when an article doesn't use front matter" do
      let(:article) do
        Article.create(user: user, title: "something", body_markdown: "blah blah #{rand(100)}", tag_list: "yoyo, bobo",
                       published: true)
      end

      it "removes the added tag" do
        delete "/tag_adjustments/#{tag_adjustment.id}", params: {
          id: tag_adjustment.id
        }
        expect(article.tag_list).not_to include tag.name
      end
    end

    context "when an article uses front matter" do
      let(:article) do
        body_markdown = "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: heyheyhey\n---\n\nHello"
        create(:article, user: user, body_markdown: body_markdown)
      end

      it "removes the added tag" do
        delete "/tag_adjustments/#{tag_adjustment.id}", params: {
          id: tag_adjustment.id
        }
        expect(article.tag_list).not_to include tag.name
      end
    end
  end
end
