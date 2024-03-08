require "rails_helper"

RSpec.describe Users::SuggestProminent, type: :service do
  describe ".call" do
    let(:user) { create(:user) }
    let(:attributes_to_select) { %i[id username] }
    let!(:featured_users) { create_list(:user, 3) }

    before do
      allow(Article).to receive(:featured).and_return(Article.all)
      allow(user).to receive(:cached_followed_tag_names).and_return([])
    end

    it "does not include the calling user" do
      suggested_users = described_class.call(user, attributes_to_select: attributes_to_select)
      expect(suggested_users).not_to include(user)
    end

    context "when specifying attributes to select" do
      it "returns users with only specified attributes" do
        suggested_users = described_class.call(user, attributes_to_select: attributes_to_select)
        suggested_user_attributes = suggested_users.first.attributes.keys
        expect(suggested_user_attributes).to match_array(attributes_to_select.map(&:to_s))
      end
    end

    context "with cached_followed_tags" do
      before do
        allow(user).to receive(:cached_followed_tag_names).and_return(["html"])
        # Ensure that each featured user has at least one article tagged with "html"
        featured_users.each do |featured_user|
          create(:article, user: featured_user, tags: ["html"]) # Adjust this line based on how you handle tags
        end
        # Stub `Article.cached_tagged_with_any` to return articles by featured users
        allow(Article).to receive(:cached_tagged_with_any).with(["html"]).and_return(Article.where(user: featured_users))
      end

      it "suggests users based on articles with matching tags" do
        suggested_users = described_class.call(user, attributes_to_select: attributes_to_select)
        article_user_ids = featured_users.map(&:id)
        suggested_user_ids = suggested_users.map(&:id)
        expect(suggested_user_ids).to all(be_in(article_user_ids))
      end
    end
  end
end
