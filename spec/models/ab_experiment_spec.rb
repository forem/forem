require "rails_helper"

RSpec.describe AbExperiment do
  let(:controller) { ApplicationController.new }
  let(:user) { double }

  before do
    allow(controller).to receive(:field_test).with(:feed_strategy, participant: user).and_return("special")
  end

  describe ".get" do
    context "with :feed_strategy experiment" do
      let(:experiment) { :feed_strategy }

      it "returns an inquirable string" do
        result = described_class.get(experiment: :feed_strategy,
                                     user: user,
                                     controller: controller,
                                     default_value: "default")
        expect(result).to eq("special")
        expect(result).to be_special
      end

      it "allows for an config override" do
        result = described_class.get(experiment: :feed_strategy,
                                     user: user,
                                     controller: controller,
                                     default_value: "special",
                                     config: { "AB_EXPERIMENT_FEED_STRATEGY" => "not_special" })
        expect(result).to eq("not_special")
        expect(result).to be_not_special
      end
    end
  end
end
