require "rails_helper"

RSpec.describe Articles::Feeds::WeightedQueryStrategy, type: :service do
  subject(:feed_strategy) { described_class.new(user: user) }

  let(:user) { create(:user) }

  describe "#call" do
    it "performs a successful query" do
      # Yes, this is not a very exciting test.  However, the purpose
      # of the test is to see if the SQL statement runs.
      article = create(:article)
      expect(feed_strategy.call).to match_array([article])
    end
  end
end
