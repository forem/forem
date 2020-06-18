require "rails_helper"

RSpec.describe WebMentions::CheckWebMentionSupport, type: :worker do
  describe "perform" do
    let(:worker) { subject }
    let(:article) { create(:article) }

    describe "check webmention support" do
      it "returns false when the canonical url doesnt support webmentions" do
        worker.perform(article.id)
        expect(article.support_webmentions).to be false
      end

      it "returns false when the webmention url is absolute" do
        article.canonical_url = "https://webmention.rocks/test/3"
        worker.perform(article.id)
        expect(article.support_webmentions).to be false
      end

      it "returns true if the canonical url supports webmentions" do
        article.canonical_url = "https://webmention.rocks/test/4"
        worker.perform(article.id)
        expect(article.support_webmentions).to be false
      end
    end
  end
end
