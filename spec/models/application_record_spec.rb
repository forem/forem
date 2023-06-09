require "rails_helper"

# ApplicationRecord is an abstract class, tests will use one of the core models
RSpec.describe ApplicationRecord do
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

  describe "batch querying respecting scope" do
    let!(:alice) { create(:user, username: "alice", confirmed_at: 12.hours.ago) }
    let!(:bob) { create(:user, username: "bob", confirmed_at: 3.days.ago) }
    let!(:charles) { create(:user, username: "charles", confirmed_at: 3.hours.ago) }
    let!(:doreen) { create(:user, username: "doreen", confirmed_at: 1.day.ago) }
    let!(:esther) { create(:user, username: "esther", confirmed_at: 2.weeks.ago) }

    describe ".in_batches_respecting_scope" do
      it "fetches records in batches of specified size" do
        expect { |block| User.in_batches_respecting_scope(batch_size: 2, &block) }
          .to yield_successive_args(
            [alice, bob],
            [charles, doreen],
            [esther],
          )
      end

      it "respects scopes such as WHERE and ORDER" do
        scope = User.where("confirmed_at > ?", 2.days.ago).order(username: :desc)
        expect { |block| scope.in_batches_respecting_scope(batch_size: 2, &block) }
          .to yield_successive_args(
            [doreen, charles],
            [alice],
          )
      end

      it "handles limit and offset appropriately regardless of batch size" do
        scope = User.order(username: :desc).limit(2).offset(2)
        expect { |block| scope.in_batches_respecting_scope(batch_size: 10, &block) }
          .to yield_successive_args([charles, bob])
      end
    end

    describe ".find_each_respecting_scope" do
      it "fetches records in batches" do
        allow(User).to receive(:in_batches_respecting_scope).with(batch_size: 2).and_call_original

        expect { |block| User.find_each_respecting_scope(batch_size: 2, &block) }
          .to yield_successive_args(alice, bob, charles, doreen, esther)

        expect(User).to have_received(:in_batches_respecting_scope).once
      end

      it "respects scopes such as WHERE and ORDER" do
        scope = User.where("confirmed_at < ?", 18.hours.ago).order(confirmed_at: :asc)
        expect { |block| scope.find_each_respecting_scope(batch_size: 2, &block) }
          .to yield_successive_args(esther, bob, doreen)
      end

      it "returns an enumerator and defers batch querying if called without a block" do
        allow(User).to receive(:in_batches_respecting_scope).and_call_original

        query = User.order(username: :desc).find_each_respecting_scope
        expect(query).to be_an(Enumerator)
        expect(User).not_to have_received(:in_batches_respecting_scope)

        expect(query.map(&:username)).to contain_exactly("esther", "doreen", "charles", "bob", "alice")
        expect(User).to have_received(:in_batches_respecting_scope)
      end
    end
  end
end
