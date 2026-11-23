require "rails_helper"

RSpec.describe "TagAdjustments" do
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

  describe "DELETE /tag_adjustments/:id permission scoping" do
    let(:admin) { create(:user, :admin) }
    let(:article) do
      Article.create(
        user: user, title: "something", body_markdown: "blah blah #{rand(100)}",
        tag_list: "#{tag.name}, yoyo, bobo", published: true
      )
    end
    let(:tag_adjustment) do
      create(:tag_adjustment, article: article, user: admin, tag: tag, tag_name: tag.name, adjustment_type: "removal")
    end

    shared_examples "rejects tag adjustment removal" do
      it "rejects the request and preserves the adjustment and article tags" do
        expect { delete "/tag_adjustments/#{tag_adjustment.id}" }.to raise_error(Pundit::NotAuthorizedError)

        expect(TagAdjustment.exists?(tag_adjustment.id)).to be true
        expect(article.reload.tag_list).not_to include(tag.name)
      end
    end

    before do
      tag_adjustment
      article.update!(tag_list: "yoyo, bobo")
    end

    context "when signed in as a trusted user without tag moderator privileges" do
      before do
        user2.add_role(:trusted)
        sign_in user2
      end

      it_behaves_like "rejects tag adjustment removal"
    end

    context "when signed in as a tag moderator for a different tag" do
      let(:other_tag) { create(:tag) }

      before do
        user2.add_role(:trusted)
        user2.add_role(:tag_moderator, other_tag)
        sign_in user2
      end

      it_behaves_like "rejects tag adjustment removal"
    end

    context "when signed in as a tag moderator for the same tag who did not create the adjustment" do
      before do
        user2.add_role(:trusted)
        user2.add_role(:tag_moderator, tag)
        sign_in user2
      end

      it_behaves_like "rejects tag adjustment removal"
    end

    context "when signed in as a tag moderator removing their own adjustment" do
      let(:tag_adjustment) do
        user2.add_role(:tag_moderator, tag)
        create(:tag_adjustment, article: article, user: user2, tag: tag, tag_name: tag.name, adjustment_type: "removal")
      end

      before do
        user2.add_role(:trusted)
        sign_in user2
      end

      it "destroys the adjustment and restores the tag" do
        delete "/tag_adjustments/#{tag_adjustment.id}"

        expect(TagAdjustment.exists?(tag_adjustment.id)).to be false
        expect(article.reload.tag_list).to include(tag.name)
      end
    end

    context "when a tag moderator loses the trusted role" do
      let(:tag_adjustment) do
        user2.add_role(:tag_moderator, tag)
        create(:tag_adjustment, article: article, user: user2, tag: tag, tag_name: tag.name, adjustment_type: "removal")
      end

      before { sign_in user2 }

      it_behaves_like "rejects tag adjustment removal"
    end

    context "when a community leader without a tag moderator role attempts to remove their own adjustment" do
      let(:tag_adjustment) do
        user2.add_role(:community_leader_level_1)
        create(:tag_adjustment, article: article, user: user2, tag: tag, tag_name: tag.name, adjustment_type: "removal")
      end

      before do
        user2.add_role(:trusted)
        sign_in user2
      end

      it_behaves_like "rejects tag adjustment removal"
    end

    context "when a former tag moderator attempts to remove an earlier adjustment" do
      let(:tag_adjustment) do
        user2.add_role(:tag_moderator, tag)
        adj = create(:tag_adjustment, article: article, user: user2, tag: tag, tag_name: tag.name,
                                      adjustment_type: "removal")
        user2.remove_role(:tag_moderator, tag)
        adj
      end

      before do
        user2.add_role(:trusted)
        sign_in user2
      end

      it_behaves_like "rejects tag adjustment removal"
    end

    context "when signed in as a super moderator" do
      before do
        user2.add_role(:super_moderator)
        sign_in user2
      end

      it "destroys the adjustment and restores the tag" do
        delete "/tag_adjustments/#{tag_adjustment.id}"

        expect(TagAdjustment.exists?(tag_adjustment.id)).to be false
        expect(article.reload.tag_list).to include(tag.name)
      end
    end

    context "when not signed in" do
      it "redirects HTML requests and preserves the adjustment and article tags", :aggregate_failures do
        delete "/tag_adjustments/#{tag_adjustment.id}"

        expect(response).to redirect_to(new_magic_link_path)
        expect(TagAdjustment.exists?(tag_adjustment.id)).to be true
        expect(article.reload.tag_list).not_to include(tag.name)
      end

      it "returns unauthorized for JSON requests and preserves the adjustment", :aggregate_failures do
        delete "/tag_adjustments/#{tag_adjustment.id}", as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(TagAdjustment.exists?(tag_adjustment.id)).to be true
        expect(article.reload.tag_list).not_to include(tag.name)
      end
    end

    context "when signed in as a suspended admin" do
      before do
        user2.add_role(:admin)
        user2.add_role(:suspended)
        sign_in user2
      end

      it_behaves_like "rejects tag adjustment removal"
    end
  end

  describe "POST /tag_adjustments validation error rendering" do
    let(:admin) { create(:user, :admin) }
    let(:other_tag) { create(:tag) }
    let(:article) do
      Article.create(
        user: user, title: "something", body_markdown: "blah blah #{rand(100)}",
        tag_list: "#{tag.name}, #{other_tag.name}, yoyo", published: true
      )
    end
    let!(:own_adjustment) do
      user2.add_role(:tag_moderator, tag)
      create(:tag_adjustment, article: article, user: user2, tag: tag, tag_name: tag.name, adjustment_type: "removal")
    end
    let!(:revoked_adjustment) do
      user2.add_role(:tag_moderator, other_tag)
      adj = create(:tag_adjustment, article: article, user: user2, tag: other_tag, tag_name: other_tag.name,
                                    adjustment_type: "removal")
      user2.remove_role(:tag_moderator, other_tag)
      adj
    end
    let!(:admin_adjustment) do
      create(:tag_adjustment, article: article, user: admin, tag: tag, tag_name: tag.name, adjustment_type: "removal")
    end

    before do
      article.update!(tag_list: "yoyo")
      user2.add_role(:trusted)
      sign_in user2
    end

    it "renders undo forms only for adjustments permitted by TagAdjustmentPolicy", :aggregate_failures do
      post "/tag_adjustments", params: {
        tag_adjustment: {
          tag_name: tag.name,
          article_id: article.id,
          adjustment_type: "removal"
        }
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("action=\"/tag_adjustments/#{own_adjustment.id}\"")
      expect(response.body).not_to include("action=\"/tag_adjustments/#{revoked_adjustment.id}\"")
      expect(response.body).not_to include("action=\"/tag_adjustments/#{admin_adjustment.id}\"")
    end
  end
end
