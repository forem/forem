require "rails_helper"

RSpec.describe CommentsHelper do
  describe "#commenter_organization_membership" do
    let(:user) { create(:user) }
    let(:organization) { create(:organization) }
    let(:article) { create(:article, organization: organization) }
    let(:comment) { create(:comment, user: user, commentable: article) }

    context "when commenter is a member of the organization" do
      before do
        create(:organization_membership, user: user, organization: organization, type_of_user: "member")
      end

      it "returns the organization name" do
        expect(helper.commenter_organization_membership(comment, article)).to eq(organization.name)
      end
    end

    context "when commenter is an admin of the organization" do
      before do
        create(:organization_membership, user: user, organization: organization, type_of_user: "admin")
      end

      it "returns the organization name" do
        expect(helper.commenter_organization_membership(comment, article)).to eq(organization.name)
      end
    end

    context "when commenter is not a member of the organization" do
      it "returns nil" do
        expect(helper.commenter_organization_membership(comment, article)).to be_nil
      end
    end

    context "when article has no organization" do
      let(:article) { create(:article, organization: nil) }

      it "returns nil" do
        expect(helper.commenter_organization_membership(comment, article)).to be_nil
      end
    end

    context "when commentable is nil" do
      it "returns nil" do
        expect(helper.commenter_organization_membership(comment, nil)).to be_nil
      end
    end

    context "with preloaded associations" do
      let!(:organization_membership) do
        create(:organization_membership, user: user, organization: organization, type_of_user: "member")
      end
      let!(:comments) { create_list(:comment, 3, user: user, commentable: article) }

      it "works with preloaded organization_memberships" do
        # Load comments with preloaded associations (like Comments::Tree does)
        loaded_comments = article.comments.includes(user: %i[setting profile organization_memberships],
                                                    commentable: :organization)

        loaded_comments.each do |loaded_comment|
          result = helper.commenter_organization_membership(loaded_comment, article)
          expect(result).to eq(organization.name)
        end
      end
    end
  end
end
