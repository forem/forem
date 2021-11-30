require "rails_helper"

RSpec.describe Articles::Feeds::WeightedQueryStrategy, type: :service do
  subject(:feed_strategy) { described_class.new(user: user) }

  describe "with a nil user" do
    let(:user) { nil }

    it "#call performs a successful query" do
      article = create(:article)
      response = feed_strategy.call
      expect(response).to be_a(ActiveRecord::Relation)
      expect(response).to match_array([article])
    end

    it "#call is successful with parameterization" do
      # NOTE: I'm not testing the SQL logic, merely that the SQL is
      # valid.
      response = feed_strategy.call(only_featured: true, must_have_main_image: true)
      expect(response).to be_a(ActiveRecord::Relation)
      expect(response).to match_array([])
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
      response = feed_strategy.call(only_featured: true, must_have_main_image: true)
      expect(response).to be_a(ActiveRecord::Relation)
      expect(response).to match_array([])
    end
  end
end
