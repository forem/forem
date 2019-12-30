require "rails_helper"

RSpec.describe Articles::DetectHumanLanguageJob, type: :job do
  include_examples "#enqueues_job", "articles_detect_human_language", [1]

  describe "#perform_now" do
    context "with article" do
      let_it_be(:article) { create(:article) }

      it "updates article language with detected language" do
        described_class.perform_now(article.id)

        expect(article.language).to eql("en")
      end
    end

    context "without aritcle" do
      it "does not error" do
        expect { described_class.perform_now(nil) }.not_to raise_error
      end
    end
  end
end
