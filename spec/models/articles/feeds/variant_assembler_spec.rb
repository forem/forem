require "rails_helper"

RSpec.describe Articles::Feeds::VariantAssembler do
  describe ".call" do
    Rails.root.glob("#{described_class::DIRECTORY}/*.#{described_class::EXTENSION}").each do |pathname|
      variant = pathname.basename(".json").to_s.to_sym
      context "for #{variant.inspect}" do
        # NOTE: We're providing the variants so as to not pollute the cache for other tests.
        subject { described_class.call(variant: variant, variants: {}) }

        it { is_expected.to be_a(Articles::Feeds::VariantQuery::Config) }
      end
    end

    context "with missing variant" do
      subject { described_class.call(variant: :obviously_missing, variants: {}) }

      it { within_block_is_expected.to raise_error(Errno::ENOENT) }
    end
  end
end
