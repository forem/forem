require "rails_helper"

RSpec.describe AbExperiment do
  let!(:controller) { ApplicationController.new }

  describe ".feed_strategy_for" do
    it "returns a string from a field test for the feed strategy" do
      user = double
      allow(controller).to receive(:field_test).with(:feed_strategy, participant: user).and_return("special")
      result = controller.feed_strategy_for(user: user)
      expect(result).to eq("special")
      expect(result).to be_special
    end

    it "allows for an ENV override" do
      user = double
      allow(controller).to receive(:field_test).with(:feed_strategy, participant: user).and_return("special")
      result = controller.feed_strategy_for(user: user,
                                            env: { "AB_EXPERIMENT_VARIANT_FEED_STRATEGY" => "not_special" })
      expect(result).to eq("not_special")
      expect(result).to be_not_special
    end
  end
end
