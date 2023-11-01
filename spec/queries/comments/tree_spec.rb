require "rails_helper"

RSpec.describe Comments::Tree, type: :query do
  let(:article) { create(:article) }
  let!(:root_comment) { create(:comment, commentable: article) }
  let!(:comments) do
    create_list(:comment, 5, commentable: article, user: article.user)
  end

  before do
    create(:comment, commentable: article, parent: root_comment)
    create(:comment, commentable: article, parent: child_comment)
  end

  describe ".for_api" do
    it "returns comments tree" do
      tree = described_class.for_api(article)
      expect(tree.size).to eq(6)
      expect(tree).to include(root_comment)
    end

    it "paginates if page is passed" do
      tree = described_class.for_api(article, page: 2, per_page: 3)
      expect(tree.size).to eq(3)
      expect(tree).not_to include(root_comment)
    end

    it "uses default per_page if it's not passed" do
      tree = described_class.for_api(article, page: 1)
      expect(tree.size).to eq(6) # number of root comments
    end

    it "doesn't paginate if invalid page is passed" do
      tree = described_class.for_api(article, page: -1, per_page: 1)
      expect(tree.size).to eq(6)
      # tree includes comments
      expect(comments - tree.keys).to be_empty
    end
  end
end
