require "rails_helper"

RSpec.describe RailsEnvConstraint, type: :lib do
  it "matches only in the correct environments", :aggregate_failures do
    constraint = described_class.new(allowed_envs: %w[development])

    allow(Rails).to receive(:env).and_return("development")
    expect(constraint.matches?).to be true

    allow(Rails).to receive(:env).and_return("production")
    expect(constraint.matches?).to be false
  end
end
