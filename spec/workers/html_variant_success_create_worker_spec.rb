require "rails_helper"

RSpec.describe HtmlVariantSuccessCreateWorker, type: :worker do
  let(:worker) { subject }

  # Passing in a random html_variant_id and article_id since the worker doesn't actually run
  include_examples "#enqueues_on_correct_queue", "default", [789, 456]

  describe "#perform" do
    before { allow(HtmlVariantSuccess).to receive(:create) }

    let(:article) { create(:article) }
    let(:html_variant) { create(:html_variant) }

    it "calls the HtmlVariantSuccessCreateWorker" do
      worker.perform(html_variant.id, article.id)

      expect(HtmlVariantSuccess).to have_received(:create).with(html_variant_id: html_variant.id,
                                                                article_id: article.id)
    end

    it "does nothing if there is missing data" do
      expect { worker.perform(nil, nil) }.not_to raise_error
    end
  end
end
