require "rails_helper"

RSpec.describe Badges::AwardEightWeekStreak, type: :service do
  it "calls Badges::AwardStreak with argument 8" do
    allow(Badges::AwardStreak).to receive(:call)
    described_class.call
    expect(Badges::AwardStreak).to have_received(:call).with(weeks: 8)
  end
end
