require "rails_helper"

RSpec.describe Articles::Feeds::VariantQuery, type: :service do
  # We're exercising each named feed variant to ensure that the queries are valid SQL.
  describe ".build_for" do
    Rails.root.glob(File.join(Articles::Feeds::VariantAssembler::DIRECTORY, "/*.json")).each do |pathname|
      variant = pathname.basename(".json").to_s.to_sym
      subject(:query_call) { variant_query.call }

      let(:variant_query) {  described_class.build_for(variant: variant, user: user) }

      context "for #{variant.inspect} and user is nil" do
        let(:user) { nil }

        it "is a valid ActiveRecord::Relation" do
          article = create(:article)
          expect(query_call).to be_a(ActiveRecord::Relation)
          expect(query_call.to_a).to match_array(article)
        end
      end

      context "for #{variant.inspect} and a non-nil user" do
        let(:user) { create(:user) }

        it "is a valid ActiveRecord::Relation" do
          article = create(:article)
          expect(query_call).to be_a(ActiveRecord::Relation)
          expect(query_call.to_a).to match_array(article)
        end
      end
    end

    Rails.root.glob("spec/fixtures/feed-variants/broken/*.json").each do |pathname|
      variant = pathname.basename(".json").to_s.to_sym

      let(:variant_config) do
        # Assembling the config and not polluting the variant cache with broken levers.
        Articles::Feeds::VariantAssembler.call(variant: variant, variants: {},
                                               dir: "spec/fixtures/feed-variants/broken")
      end

      # We already assembled the variant's config, let's short circuit that for the query
      let(:stubbed_assembler) { ->(*) { variant_config } }

      context "for broken variant #{variant.inspect} and a non-nil user" do
        let(:variant_query) { described_class.build_for(variant: variant, user: user, assembler: stubbed_assembler) }
        let(:user) { create(:user) }

        it { within_block_is_expected.to raise_error(Articles::Feeds::RelevancyLever::ConfigurationError) }
      end

      context "for broken variant #{variant.inspect} and a nil user" do
        let(:variant_query) { described_class.build_for(variant: variant, user: user, assembler: stubbed_assembler) }
        let(:user) { nil }

        it { within_block_is_expected.to raise_error(Articles::Feeds::RelevancyLever::ConfigurationError) }
      end
    end
  end
end
