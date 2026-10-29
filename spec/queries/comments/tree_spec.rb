require "rails_helper"

RSpec.describe Comments::Tree do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let!(:comment) { create(:comment, user: user, commentable: article) }
  let!(:other_comment) { create(:comment, commentable: article, user: user, created_at: 1.hour.from_now) }
  let!(:child_comment) { create(:comment, commentable: article, parent: comment, user: user) }

  before { comment.update_column(:score, 1) }

  describe "#for_commentable" do
    it "returns a full tree" do
      comments = described_class.for_commentable(article)
      expect(comments).to eq(comment => { child_comment => {} }, other_comment => {})
    end

    it "preloads user roles, profile, and setting on returned comments" do
      comments = described_class.for_commentable(article)
      root_comment = comments.keys.first

      expect(root_comment.user.association(:roles)).to be_loaded
      expect(root_comment.user.association(:profile)).to be_loaded
      expect(root_comment.user.association(:setting)).to be_loaded
      expect(root_comment.user.association(:organization_memberships)).to be_loaded
    end

    it "reuses the passed article and its loaded user instead of re-fetching them" do
      article.update_column(:user_id, user.id)
      loaded_article = Article.find(article.id)
      loaded_article.user

      queries = []
      callback = lambda do |*, payload|
        queries << payload[:sql] if payload[:sql].include?('FROM "articles"') || payload[:sql].include?('FROM "users"')
      end
      tree = ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.for_commentable(loaded_article)
      end

      expect(queries).to be_empty
      nodes = Comment.flatten_arranged_nodes(tree)
      expect(nodes.map(&:commentable)).to all(be(loaded_article))
      expect(nodes.map(&:user)).to all(be(loaded_article.user))
      expect(loaded_article.association(:organization)).to be_loaded
      expect(loaded_article.user.association(:profile)).to be_loaded
      expect(loaded_article.user.association(:setting)).to be_loaded
    end

    it "skips association preloads when all root comments are filtered out" do
      comment.update_column(:score, -5)
      other_comment.update_column(:score, -10)

      user_queries = []
      callback = lambda do |*, payload|
        user_queries << payload[:sql] if payload[:sql].include?('FROM "users"')
      end
      tree = ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.for_commentable(article, include_negative: false)
      end

      expect(tree).to be_empty
      expect(user_queries).to be_empty
    end

    it "returns part of the tree" do
      comments = described_class.for_commentable(article, limit: 1)
      expect(comments).to eq(comment => { child_comment => {} })
    end

    it "supports deferring association preloads via preload: false and preload_for_tree", :aggregate_failures do
      create(:comment, commentable: article, parent: other_comment, user: user)

      user_queries = []
      callback = lambda do |*, payload|
        sql = payload[:sql]
        user_queries << sql if sql.include?('FROM "users"') || sql.include?('FROM "profiles"')
      end

      full_tree = ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.for_commentable(article, preload: false)
      end

      included_root, excluded_root = full_tree.keys
      retained_child = full_tree[included_root].keys.first
      excluded_child = full_tree[excluded_root].keys.first

      expect(user_queries).to be_empty
      expect(included_root.association(:user)).not_to be_loaded

      trimmed_tree = { included_root => { retained_child => {} } }
      described_class.preload_for_tree(trimmed_tree, commentable: article)

      expect(included_root.association(:user)).to be_loaded
      expect(included_root.user.association(:profile)).to be_loaded
      expect(included_root.user.association(:setting)).to be_loaded
      expect(included_root.user.association(:roles)).to be_loaded
      expect(included_root.user.association(:organization_memberships)).to be_loaded
      expect(retained_child.association(:user)).to be_loaded
      expect(retained_child.user.association(:profile)).to be_loaded
      expect(retained_child.user.association(:setting)).to be_loaded
      expect(retained_child.user.association(:roles)).to be_loaded
      expect(retained_child.user.association(:organization_memberships)).to be_loaded
      expect(excluded_root.association(:user)).not_to be_loaded
      expect(excluded_child.association(:user)).not_to be_loaded
    end

    context "with include_negative" do
      before do
        other_comment.update_column(:score, -10)
      end

      it "returns comments with low score if include_negative is passed" do
        comments = described_class.for_commentable(article, include_negative: true)
        expect(comments).to eq({ comment => { child_comment => {} }, other_comment => {} })
      end

      it "doesn't return comments with low score if include_negative is false" do
        comments = described_class.for_commentable(article)
        expect(comments).to eq(comment => { child_comment => {} })
      end
    end

    context "with sort order" do
      let!(:new_comment) { create(:comment, commentable: article, user: user, created_at: Date.tomorrow) }
      let!(:old_comment) { create(:comment, commentable: article, user: user, created_at: Date.yesterday) }

      before { comment }

      it "returns comments in the right order when order is oldest" do
        comments = described_class.for_commentable(article, limit: 0, order: "oldest")
        comments = comments.map { |key, _| key.id }
        expect(comments).to contain_exactly(old_comment.id, comment.id, other_comment.id, new_comment.id)
      end

      it "returns comments in the right order when order is latest" do
        comments = described_class.for_commentable(article, limit: 0, order: "latest")
        comments = comments.map { |key, _| key.id }
        expect(comments).to contain_exactly(new_comment.id, other_comment.id, comment.id, old_comment.id)
      end

      it "returns comments in the right order when order is top" do
        comment.update_column(:score, 5)
        highest_rated_comment = comment
        new_comment.update_column(:score, 1)
        lowest_rated_comment = new_comment
        old_comment.update_column(:score, 3)
        mid_high_rated_comment = old_comment
        other_comment.update_column(:score, 2)
        mid_low_rated_comment = other_comment
        comments = described_class.for_commentable(article, limit: 0)

        comments = comments.map { |key, _| key.id }
        expect(comments).to eq([highest_rated_comment.id, mid_high_rated_comment.id, mid_low_rated_comment.id, lowest_rated_comment.id]) # rubocop:disable Layout/LineLength
      end
    end
  end

  describe "#for_root_comment" do
    let!(:low_comment) { create(:comment, commentable: article, parent: comment, score: -100) }

    it "returns tree for a particular comment" do
      comments = described_class.for_root_comment(comment)
      expect(comments).to eq(comment => { child_comment => {} })
    end

    it "returns tree with negative comments" do
      comments = described_class.for_root_comment(comment, include_negative: true)
      expect(comments).to eq(comment => { child_comment => {}, low_comment => {} })
    end

    it "reuses the root comment's loaded article instead of re-fetching it" do
      root = Comment.find(comment.id)
      root.commentable

      article_queries = []
      callback = lambda do |*, payload|
        article_queries << payload[:sql] if payload[:sql].include?('FROM "articles"')
      end
      tree = ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.for_root_comment(root)
      end

      expect(article_queries).to be_empty
      nodes = [tree.keys.first, *tree.values.first.keys]
      expect(nodes.map(&:commentable)).to all(be(root.commentable))
      expect(root.commentable.association(:organization)).to be_loaded
    end

    it "preloads user associations onto the returned root comment" do
      root = Comment.find(comment.id)
      tree = described_class.for_root_comment(root)
      root_comment = tree.keys.first

      expect(root_comment.association(:user)).to be_loaded
      expect(root_comment.user.association(:roles)).to be_loaded
      expect(root_comment.user.association(:profile)).to be_loaded
      expect(root_comment.user.association(:setting)).to be_loaded
      expect(root_comment.user.association(:organization_memberships)).to be_loaded
    end

    it "reuses the root comment's loaded user instead of re-fetching it" do
      root = Comment.find(comment.id)
      root.user

      user_queries = []
      callback = lambda do |*, payload|
        user_queries << payload[:sql] if payload[:sql].include?('FROM "users"')
      end
      tree = ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.for_root_comment(root)
      end

      expect(user_queries).to be_empty
      nodes = [tree.keys.first, *tree.values.first.keys]
      expect(nodes.map(&:user)).to all(be(root.user))
      expect(root.user.association(:profile)).to be_loaded
      expect(root.user.association(:setting)).to be_loaded
    end

    it "scopes descendant lookup by commentable and avoids re-fetching root_comment by id", :aggregate_failures do
      root = Comment.find(comment.id)

      comment_queries = []
      callback = lambda do |*, payload|
        next if payload[:name] == "SCHEMA"

        comment_queries << payload[:sql] if payload[:sql].include?('FROM "comments"')
      end
      tree = ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.for_root_comment(root)
      end

      expect(tree).to eq(comment => { child_comment => {} })
      expect(comment_queries.size).to eq(1)
      expect(comment_queries.first).to include('"comments"."commentable_id"')
      expect(comment_queries.first).to include('"comments"."commentable_type"')
      expect(comment_queries.first).not_to include('"comments"."id" =')
    end
  end
end
