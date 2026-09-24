require "rails_helper"

RSpec.describe Articles::PageViewUpdater do
  describe "#call" do
    subject(:method_call) { described_class.call(article_id: article.id, user_id: user.id) }

    let(:user) { create(:user) }

    context "when article published and written by another user" do
      let(:article) { create(:article, user: create(:user)) }

      it "updates a user's page view" do
        expect { method_call }.to change(PageView, :count)
      end
    end

    context "when article is unpublished" do
      let(:article) { create(:article, published: false, published_at: nil) }

      it "skips updating" do
        expect { method_call }.not_to change(PageView, :count)
      end
    end

    context "when article written by given user" do
      let(:article) { create(:article, user: user) }

      it "skips updating" do
        expect { method_call }.not_to change(PageView, :count)
      end
    end

    context "when time count equals EXTENDED_PAGEVIEW_NUMBER" do
      let(:article) { create(:article, user: create(:user)) }

      before do
        create(:feed_event, user: user, article: article, category: :click)
      end

      it "sends a feed event journey and enqueues interest embedding when it receives a page view length of 60" do
        allow(UpdateUserInterestEmbeddingWorker).to receive(:perform_async)
        4.times do
          described_class.call(article_id: article.id, user_id: user.id)
        end
        expect(FeedEvent.last.category).to eq("extended_pageview")
        expect(UpdateUserInterestEmbeddingWorker).to have_received(:perform_async).with(user.id, article.id, 0.05)
      end

      it "does not send feed event journey when it receives a page view length of less than 60" do
        2.times do
          described_class.call(article_id: article.id, user_id: user.id)
        end
        expect(FeedEvent.all.size).to be 1
      end

      it "only sends one event when it passes through the 60 range" do
        8.times do
          described_class.call(article_id: article.id, user_id: user.id)
        end
        expect(FeedEvent.all.size).to be 2
      end
    end

    context "when emitting the article_read CDP event" do
      let(:article) { create(:article, user: create(:user), tags: "ruby, rails") }
      let(:events) { [] }

      before do
        allow(Trackable::Registry).to receive(:active_names).and_return([:any])
        allow(Trackable::DispatchWorker).to receive(:perform_async) do |_adapter, name, ids, props, _ts|
          events << { name: name, user_ids: ids, properties: props }
        end
        Settings::General.customerio_cdp_enabled = true
        FeatureFlag.enable(:dev_core_user_sync)
      end

      after { FeatureFlag.remove(:dev_core_user_sync) }

      around { |ex| with_trackable_events { ex.run } }

      def read_events
        events.select { |event| event[:name] == "article_read" }
      end

      it "emits article_read keyed to the reader once the 60 second mark is crossed" do
        4.times { described_class.call(article_id: article.id, user_id: user.id) }

        expect(read_events.size).to eq(1)
        event = read_events.first
        expect(event[:user_ids]).to eq([user.id])
        expect(event[:properties]).to include(
          "article_id" => article.id,
          "title" => article.title,
          "url" => URL.article(article, user_signed_in: false),
          "tags" => %w[ruby rails],
          "author_username" => article.user.username,
        )
      end

      it "stays silent before the 60 second mark" do
        2.times { described_class.call(article_id: article.id, user_id: user.id) }

        expect(read_events).to be_empty
      end

      it "emits only once when reading continues past 60 seconds" do
        8.times { described_class.call(article_id: article.id, user_id: user.id) }

        expect(read_events.size).to eq(1)
      end

      # The sibling FeedEvent requires a preceding feed click; this event does not,
      # so feed-sourced and organic reads are both campaign-triggerable.
      it "emits without any preceding feed click" do
        expect(FeedEvent.where(user: user, category: :click)).to be_empty

        4.times { described_class.call(article_id: article.id, user_id: user.id) }

        expect(read_events.size).to eq(1)
      end
    end
  end
end
