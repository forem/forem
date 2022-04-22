require "rails_helper"

RSpec.describe Articles::Feeds::VariantQuery, type: :service do
  # We're exercising each named feed variant to ensure that the queries are valid SQL.
  describe ".build_for" do
    Rails.root.glob(File.join(Articles::Feeds::VariantAssembler::DIRECTORY, "/*.json")).each do |pathname|
      variant = pathname.basename(".json").to_s.to_sym
      subject(:query_call) { variant_query.call }

      let(:variant_query) {  described_class.build_for(variant: variant, user: user) }

      context "for #call with #{variant.inspect} and user is nil" do
        let(:user) { nil }

        it "is a valid ActiveRecord::Relation" do
          article = create(:article)
          expect(query_call).to be_a(ActiveRecord::Relation)
          expect(query_call.to_a).to match_array(article)
        end
      end

      context "for #call with #{variant.inspect} and a non-nil user" do
        let(:user) { create(:user) }

        it "is a valid ActiveRecord::Relation" do
          article = create(:article)
          expect(query_call).to be_a(ActiveRecord::Relation)
          expect(query_call.to_a).to match_array(article)
        end
      end

      context "for #featured_story_and_default_home_feed with #{variant.inspect}" do
        let(:user) { nil }

        it "returns an array with two elements and entries", aggregate_failures: true do
          create_list(:article, 3)
          response = variant_query.featured_story_and_default_home_feed(user_signed_in: false)
          expect(response).to be_a(Array)
          expect(response[0]).to be_a(Article)
          expect(response[1]).to be_a(ActiveRecord::Relation)
          # You cannot use "count" because the constructed query
          # includes a select clause which gums up the counting
          # mechanism.
          expect(response[1].length).to eq(3)
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
