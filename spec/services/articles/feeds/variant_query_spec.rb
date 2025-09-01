require "rails_helper"

RSpec.describe Articles::Feeds::VariantQuery, type: :service do
  # We're exercising each named feed variant to ensure that the queries are valid SQL.
  # Only test the 3 most recent variant files to reduce test time
  Rails.root.glob(File.join(Articles::Feeds::VariantAssembler::DIRECTORY, "/*.json"))
       .sort_by(&:basename)
       .reverse
       .first(3)
       .each do |pathname|
    variant = pathname.basename(".json").to_s.to_sym

    describe ".build_for with #{variant} variant" do
      subject(:query_call) { variant_query.call }

      let(:variant_query) {  described_class.build_for(variant: variant, user: user) }

      describe "#call with nil user" do
        let(:user) { nil }

        it "is a valid ActiveRecord::Relation", :aggregate_failures do
          article = create(:article)
          expect(query_call).to be_a(ActiveRecord::Relation)
          expect(query_call.to_a).to match_array(article)
        end
      end

      describe "#call with a non-nil user" do
        let(:user) { create(:user) }

        it "is a valid ActiveRecord::Relation", :aggregate_failures do
          article = create(:article)
          expect(query_call).to be_a(ActiveRecord::Relation)
          expect(query_call.to_a).to match_array(article)
        end

        it "does not return negative scored articles", :aggregate_failures do
          article = create(:article, score: -1)
          expect(query_call).to be_a(ActiveRecord::Relation)
          expect(query_call.to_a).not_to match_array(article)
        end

        it "does not return an article published 27 hours before last page view if last comment at is too old" do
          create_list(:page_view, 5, user: user) # Recent pageviews
          article = create(:article)
          article.update_columns(published_at: 27.hours.ago, last_comment_at: 22.hours.ago)
          expect(query_call).to be_a(ActiveRecord::Relation)
          expect(query_call.to_a).not_to include(article)
        end

        it "does return article published 27 hours before last page view if last comment is within 6 hours" do
          create_list(:page_view, 5, user: user) # Recent pageviews
          article = create(:article)
          article.update_columns(published_at: 27.hours.ago, last_comment_at: 4.hours.ago)
          expect(query_call).to be_a(ActiveRecord::Relation)
          expect(query_call.to_a).to include(article)
        end

        it "does not return article published 38 hours before last page view if last comment is within 6 hours" do
          create_list(:page_view, 5, user: user) # Recent pageviews
          article = create(:article)
          article.update_columns(published_at: 38.hours.ago, last_comment_at: 4.hours.ago)
          expect(query_call).to be_a(ActiveRecord::Relation)
          expect(query_call.to_a).not_to include(article)
        end

        it "returns proper scope when passed the different test values" do
          # rubocop:disable Performance/CollectionLiteralInLoop
          %w[top_comments
             more_inclusive_top_comments
             recent_good_comments
             more_inclusive_recent_good_comments
             most_inclusive_recent_good_comments].each do |test_value|
            expect(variant_query.call(comments_variant: test_value).includes_values)
              .to include(:distinct_reaction_categories, { test_value.to_sym => :user })
          end
          # rubocop:enable Performance/CollectionLiteralInLoop
        end
      end

      describe "#featured_story_and_default_home_feed" do
        let(:user) { nil }

        it "returns an array with two elements and entries", :aggregate_failures do
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
  end

  Rails.root.glob("spec/fixtures/feed-variants/broken/*.json").each do |pathname|
    variant = pathname.basename(".json").to_s.to_sym
    describe ".build_for with broken #{variant} variant" do
      subject(:query_call) { variant_query.call }

      let(:variant_config) do
        # Assembling the config and not polluting the variant cache with broken levers.
        Articles::Feeds::VariantAssembler.call(variant: variant, variants: {},
                                               dir: "spec/fixtures/feed-variants/broken")
      end
      let(:variant_query) { described_class.build_for(variant: variant, user: user, assembler: stubbed_assembler) }

      # We already assembled the variant's config, let's short circuit that for the query
      let(:stubbed_assembler) { ->(*) { variant_config } }

      context "with a non-nil user" do
        let(:user) { create(:user) }

        it { within_block_is_expected.to raise_error(Articles::Feeds::RelevancyLever::ConfigurationError) }
      end

      context "with a nil user" do
        let(:user) { nil }

        it { within_block_is_expected.to raise_error(Articles::Feeds::RelevancyLever::ConfigurationError) }
      end
    end
  end
end
