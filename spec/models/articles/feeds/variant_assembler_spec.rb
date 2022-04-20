require "rails_helper"

RSpec.describe Articles::Feeds::VariantAssembler do
  describe ".call" do
    Rails.root.glob("config/feed-variants/*.json").each do |pathname|
      variant = pathname.basename(".json").to_s.to_sym
      context "for #{variant.inspect}" do
        # NOTE: We're providing the variants so as to not pollute the cache for other tests.
        subject { described_class.call(variant: variant, variants: {}) }

        it { is_expected.to be_a(Articles::Feeds::VariantQueryConfig) }
      end
    end
  end
end
