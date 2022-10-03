require "rails_helper"

# ApplicationRecord is an abstract class, tests will use one of the core models
RSpec.describe ApplicationRecord, type: :model do
  describe ".estimated_count" do
    it "does not raise errors if there are no rows" do
      expect { User.estimated_count }.not_to raise_error
    end
  end

  describe "#class_name" do
    it "is expected to be a string" do
      user = User.new
      expect(user.class_name).to eq("User")
    end
  end

  describe "#decorate" do
    it "decorates an object that has a decorator" do
      article = build(:article)
      expect(article.decorate).to be_a(ArticleDecorator)
    end

    it "raises an error if an object has no decorator" do
      badge = build(:badge)
      expect { badge.decorate }.to raise_error(UninferrableDecoratorError)
    end
  end

  describe "#decorated?" do
    it "returns false" do
      article = build(:article)
      expect(article.decorated?).to be(false)
    end
  end

  describe ".decorate" do
    before do
      create(:article, approved: true)
    end

    it "decorates a relation" do
      decorated_collection = Article.approved.decorate
      expect(decorated_collection.size).to eq(Article.approved.size)
      expect(decorated_collection.first).to be_a(ArticleDecorator)
    end
  end

  describe ".with_statement_timeout" do
    it "sets the SQL statement timeout to the specified duration" do
      original_timeout = described_class.statement_timeout

      described_class.with_statement_timeout 1.second do
        expect(described_class.statement_timeout).to eq 1.second

        described_class.with_statement_timeout 10.seconds do
          expect(described_class.statement_timeout).to eq 10.seconds
        end

        expect(described_class.statement_timeout).to eq 1.second
      end

      expect(described_class.statement_timeout).to eq original_timeout
    end
  end
end
