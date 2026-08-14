require "rails_helper"

RSpec.describe ReactionCounterSyncWorker, type: :worker do
  describe "#perform" do
    context "with inconsistent article counter" do
      it "fixes article with counter lower than actual reactions" do
        article = create(:article)
        create_list(:reaction, 3, reactable: article, category: "like")

        # Force counter out of sync (lower than actual)
        Article.where(id: article.id).update_all(public_reactions_count: 1)

        described_class.new.perform

        article.reload
        expect(article.public_reactions_count).to eq(3)
      end

      it "fixes article with counter higher than actual reactions" do
        article = create(:article)
        create(:reaction, reactable: article, category: "like")

        # Force counter out of sync (higher than actual)
        Article.where(id: article.id).update_all(public_reactions_count: 10)

        described_class.new.perform

        article.reload
        expect(article.public_reactions_count).to eq(1)
      end
    end

    context "with inconsistent comment counter" do
      it "fixes comment with wrong counter" do
        comment = create(:comment)
        create_list(:reaction, 2, reactable: comment, category: "like")

        # Force counter out of sync
        Comment.where(id: comment.id).update_all(public_reactions_count: 0)

        described_class.new.perform("comments")

        comment.reload
        expect(comment.public_reactions_count).to eq(2)
      end
    end

    context "with sample mode" do
      it "syncs a limited sample of records" do
        articles = create_list(:article, 5)
        articles.each do |article|
          create(:reaction, reactable: article, category: "like")
          Article.where(id: article.id).update_all(public_reactions_count: 0)
        end

        # Sample mode should fix some records
        described_class.new.perform("sample", 3)

        fixed_count = articles.count { |a| a.reload.public_reactions_count == 1 }
        expect(fixed_count).to be >= 1
      end
    end

    context "with consistent counters" do
      it "does not modify correctly synced articles" do
        article = create(:article)
        create_list(:reaction, 2, reactable: article, category: "like")
        article.reload
        expect(article.public_reactions_count).to eq(2)

        described_class.new.perform

        article.reload
        expect(article.public_reactions_count).to eq(2)
      end
    end

    context "with mode parameter" do
      it "syncs only articles when mode is 'articles'" do
        article = create(:article)
        comment = create(:comment)
        create(:reaction, reactable: article, category: "like")
        create(:reaction, reactable: comment, category: "like")

        Article.where(id: article.id).update_all(public_reactions_count: 0)
        Comment.where(id: comment.id).update_all(public_reactions_count: 0)

        described_class.new.perform("articles")

        expect(article.reload.public_reactions_count).to eq(1)
        expect(comment.reload.public_reactions_count).to eq(0)
      end

      it "syncs only comments when mode is 'comments'" do
        article = create(:article)
        comment = create(:comment)
        create(:reaction, reactable: article, category: "like")
        create(:reaction, reactable: comment, category: "like")

        Article.where(id: article.id).update_all(public_reactions_count: 0)
        Comment.where(id: comment.id).update_all(public_reactions_count: 0)

        described_class.new.perform("comments")

        expect(article.reload.public_reactions_count).to eq(0)
        expect(comment.reload.public_reactions_count).to eq(1)
      end
    end
  end
end
