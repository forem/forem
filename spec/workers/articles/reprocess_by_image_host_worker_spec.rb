require "rails_helper"

RSpec.describe Articles::ReprocessByImageHostWorker, type: :worker do
  let(:worker) { subject }
  let(:host) { "cdn.hashnode.com" }
  let(:stale_html) { %(<p><img src="https://#{host}/foo.png"></p>) }

  include_examples "#enqueues_on_correct_queue", "low_priority", ["cdn.example.com"]

  describe "#perform" do
    it "is a no-op for a blank host" do
      expect(Article).not_to receive(:where)
      worker.perform("")
    end

    it "re-evaluates only published articles whose processed_html references the host" do
      matching = create(:article)
      non_matching = create(:article)
      unpublished = create(:article, published: false)
      matching.update_column(:processed_html, stale_html)
      non_matching.update_column(:processed_html, "<p>nothing to see</p>")
      unpublished.update_column(:processed_html, stale_html)

      worker.perform(host)

      expect(matching.reload.processed_html).not_to include(host)
      expect(non_matching.reload.processed_html).to eq("<p>nothing to see</p>")
      expect(unpublished.reload.processed_html).to eq(stale_html)
    end

    it "respects a positive limit" do
      articles = Array.new(3) do
        create(:article).tap { |a| a.update_column(:processed_html, stale_html) }
      end

      worker.perform(host, 2)

      reprocessed = articles.count { |a| !a.reload.processed_html.include?(host) }
      expect(reprocessed).to eq(2)
    end

    it "respects a since cutoff" do
      recent = create(:article)
      old = create(:article)
      recent.update_columns(processed_html: stale_html, published_at: 5.days.ago)
      old.update_columns(processed_html: stale_html, published_at: 60.days.ago)

      worker.perform(host, 0, 30.days.ago.iso8601)

      expect(recent.reload.processed_html).not_to include(host)
      expect(old.reload.processed_html).to eq(stale_html)
    end

    it "ignores an unparseable since value and processes everything" do
      article = create(:article)
      article.update_column(:processed_html, stale_html)

      worker.perform(host, 0, "not-a-date")

      expect(article.reload.processed_html).not_to include(host)
    end
  end
end
