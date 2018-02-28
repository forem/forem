require "rails_helper"

RSpec.describe "Following/Unfollowing", type: :request do
  let(:user) { create(:user) }
  let(:user_2) { create(:user) }

  describe "POST #create" do
    before do
      login_as user
    end

    context "when followable_type is a Tag" do
      let(:tag) { create(:tag) }

      before do
        post "/follows", params: { followable_type: "Tag", followable_id: tag.id }
      end

      it "follows" do
        expect(JSON.parse(response.body)["outcome"]).to eq("followed")
      end

      it "unfollows if already followed" do
        post "/follows", params: { followable_type: "Tag", followable_id: tag.id, verb: "unfollow" }
        expect(JSON.parse(response.body)["outcome"]).to eq("unfollowed")
      end
    end

    context "when followable_type is a User" do
      before do
        post "/follows", params: {
          followable_type: "User", followable_id: user_2.id
        }
      end

      it "follows" do
        expect(JSON.parse(response.body)["outcome"]).to eq("followed")
      end

      it "unfollows if already followed" do
        post "/follows", params: {
          followable_type: "User", followable_id: user_2.id, verb: "unfollow"
        }
        expect(JSON.parse(response.body)["outcome"]).to eq("unfollowed")
      end
    end

    context "when followable_type is an Organization" do
      let(:organization) { create(:organization) }

      before do
        post "/follows", params: {
          followable_type: "Organization", followable_id: organization.id
        }
      end

      it "follows" do
        expect(JSON.parse(response.body)["outcome"]).to eq("followed")
      end

      it "unfollows if already followed" do
        post "/follows", params: {
          followable_type: "Organization", followable_id: organization.id, verb: "unfollow"
        }
        expect(JSON.parse(response.body)["outcome"]).to eq("unfollowed")
      end
    end

    it "returns articles of tag the user follows" do
      article = create(:article)
      user.follow(Tag.find_by_name(article.tag_list.first))
      get "/followed_articles"
      expect(JSON.parse(response.body)["articles"].first["title"]).to eq(article.title)
    end
  end
end
