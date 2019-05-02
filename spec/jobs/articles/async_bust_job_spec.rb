require "rails_helper"

RSpec.describe Articles::AsyncBustJob, type: :job do
  describe "#perform_now" do
    let(:article) { FactoryBot.create(:article) }

    it "async busts cache" do
      cache_buster = double
      allow(cache_buster).to receive(:bust_article)

      described_class.perform_now(article.id, cache_buster) do
        expect(cache_buster).to have_receive(:bust_article).with(article)
      end
    end
  end
end
