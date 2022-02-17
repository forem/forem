require "rails_helper"

RSpec.describe LoomTag do
  subject(:loom_tag) { described_class }

  let(:article) { create(:article) }
  let(:user) { create(:user) }
  let(:parse_context) { { source: article, user: user } }
  let(:valid_loom_share_url) { "https://loom.com/share/12fb674d39dd4fe281becee7cdbc3cd1" }
  let(:valid_loom_embed_url) { "https://loom.com/embed/12fb674d39dd4fe281becee7cdbc3cd1" }
  let(:valid_www_loom_url) { "https://www.loom.com/share/12fb674d39dd4fe281becee7cdbc3cd1" }

  let(:invalid_loom_urls) do
    [
      "https://loom.com/embed/should_have_no_underscores",
      "https://loom.com/embed/should-have-no-dashes",
    ]
  end

  describe "Loom tag" do
    it "returns StandardError for invalid Loom URL", :aggregate_failures do
      invalid_loom_urls.each do |invalid_url|
        expect do
          described_class.__send__(:new, "embed", invalid_url, parse_context)
        end.to raise_error(StandardError, "Invalid Loom URL.")
      end
    end
  end
end
