require "rails_helper"

RSpec.describe Articles::Feeds::WeightedQueryStrategy, type: :service do
  subject(:feed_strategy) { described_class.new(user: user) }

  let(:user) { nil }

  describe "#default_home_feed" do
    # This test helps test the common interface between the
    # WeightedQueryStrategy and the LargeForemExperimental
    it "receives `user_signed_in: false` and behaves" do
      response = feed_strategy.default_home_feed(user_signed_in: false)
      expect(response).to be_a(ActiveRecord::Relation)

      create_list(:article, 3)
    end
  end

  describe "with a nil user" do
    let(:user) { nil }

    describe "#featured_story_and_default_home_feed" do
      it "returns an array with two elements and entries", aggregate_failures: true do
        create_list(:article, 3)
        response = feed_strategy.featured_story_and_default_home_feed(user_signed_in: false)
        expect(response).to be_a(Array)
        expect(response[0]).to be_a(Article)
        expect(response[1]).to be_a(ActiveRecord::Relation)
        # You cannot use "count" because the constructed query
        # includes a select clause which gums up the counting
        # mechanism.
        expect(response[1].length).to eq(3)
      end
    end

    describe "#call" do
      it "performs a successful query" do
        article = create(:article)
        response = feed_strategy.call
        expect(response).to be_a(ActiveRecord::Relation)
        expect(response).to match_array([article])
      end

      it "is successful with parameterization" do
        # NOTE: I'm not testing the SQL logic, merely that the SQL is
        # valid.
        response = feed_strategy.call(only_featured: true)
        expect(response).to be_a(ActiveRecord::Relation)
        expect(response).to match_array([])
      end

      it "returns handles omit_article_ids scenarios as detailed below", aggregate_failures: true do
        articles = create_list(:article, 3)

        # This scenario can happen with
        # `Articles::Feeds::WeightedQueryStrategy#featured_story_and_default_home_feed`
        # when we look for a "featured" article and don't find any.
        # So let's make sure we get back the articles we were
        # expecting instead of none of them.
        expect(feed_strategy.call(omit_article_ids: [nil]).length).to eq(articles.length)
        expect(feed_strategy.call(omit_article_ids: []).length).to eq(articles.length)
        expect(feed_strategy.call(omit_article_ids: [articles.first.id]).length).to eq(articles.length - 1)
      end
    end
  end

  describe "with a non-nil user" do
    let(:user) { create(:user) }

    describe "with modified :scoring_configs" do
      subject(:feed_strategy) { described_class.new(user: user, scoring_configs: scoring_configs) }

      let(:scoring_configs) do
        {
          # Overriding the configuration for this scoring factor.
          daily_decay_factor: { cases: [[0, 1]], fallback: 1 },
          # Using the scoring factor as configured.
          comments_count_factor: true,
          # Ignoring a clause that will break things
          experience_factor: { clause: "no_such_table", cases: [[0, 1]], fallback: 1 }
        }
      end

      it "#call performs a successful query" do
        # Yes, this is not a very exciting test.  However, the purpose
        # of the test is to see if the SQL statement runs.
        article = create(:article)
        response = feed_strategy.call
        expect(response).to be_a(ActiveRecord::Relation)
        expect(response).to match_array([article])
      end
    end

    it "#call performs a successful query" do
      # Yes, this is not a very exciting test.  However, the purpose
      # of the test is to see if the SQL statement runs.
      article = create(:article)
      response = feed_strategy.call

      expect(response).to be_a(ActiveRecord::Relation)
      expect(response).to match_array([article])
    end

    it "#call is successful with parameterization" do
      # NOTE: I'm not testing the SQL logic, merely that the SQL is
      # valid.
      response = feed_strategy.call(only_featured: true)
      expect(response).to be_a(ActiveRecord::Relation)
      expect(response).to match_array([])
    end
  end
end
