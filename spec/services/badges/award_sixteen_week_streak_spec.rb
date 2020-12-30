require "rails_helper"

RSpec.describe Badges::AwardSixteenWeekStreak, type: :service do
  it "calls Badges::AwardStreak with argument 16" do
    allow(Badges::AwardStreak).to receive(:call)
    described_class.call
    expect(Badges::AwardStreak).to have_received(:call).with(weeks: 16)
  end
end
