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

  describe "#article_comment_tree" do
    let(:article) { create(:article) }
    let(:comment) { create(:comment, commentable: article) }
    let(:preloaded_tree) { { comment => {} } }

    before do
      helper.define_singleton_method(:user_signed_in?) { false }
    end

    it "reuses a tree already loaded on the article with the same options" do
      allow(Comments::Tree).to receive(:for_commentable).and_return(preloaded_tree)
      article.comment_tree(limit: 10, order: "top", include_negative: false)

      expect(helper.article_comment_tree(article, 10, "top")).to eq(preloaded_tree)
      expect(Comments::Tree).to have_received(:for_commentable).once
    end

    it "loads a separate tree when the options differ" do
      allow(Comments::Tree).to receive(:for_commentable).and_return(preloaded_tree)
      article.comment_tree(limit: 10, order: "top", include_negative: false)

      helper.article_comment_tree(article, 10, "latest")

      expect(Comments::Tree).to have_received(:for_commentable)
        .with(article, limit: 10, order: "latest", include_negative: false)
      expect(Comments::Tree).to have_received(:for_commentable).twice
    end
  end

  describe "#any_negative_comments?" do
    let(:article) { create(:article) }

    it "returns false without querying comments when the article has no comments" do
      queries = []
      callback = lambda do |*, payload|
        next if payload[:name] == "SCHEMA"

        queries << payload[:sql] if payload[:sql].include?('"comments"')
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(helper.any_negative_comments?(article)).to be(false)
      end

      expect(queries).to be_empty
    end

    it "checks preloaded comments in memory without querying the database" do
      create(:comment, commentable: article, score: -5)
      article.reload
      article.comments.load

      queries = []
      callback = lambda do |*, payload|
        next if payload[:name] == "SCHEMA"

        queries << payload[:sql] if payload[:sql].include?('"comments"')
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(helper.any_negative_comments?(article)).to be(true)
      end

      expect(queries).to be_empty
    end

    it "queries the database and returns true when an unloaded comment has a negative score" do
      create(:comment, commentable: article, score: -5)
      article.reload

      expect(helper.any_negative_comments?(article)).to be(true)
    end

    it "queries the database and returns false when all unloaded comments have non-negative scores" do
      create(:comment, commentable: article, score: 5)
      article.reload

      expect(helper.any_negative_comments?(article)).to be(false)
    end
  end
end
