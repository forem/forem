require "rails_helper"

RSpec.describe Badges::AwardFourWeekStreak, type: :service do
  it "calls Badges::AwardStreak with argument 4" do
    allow(Badges::AwardStreak).to receive(:call)
    described_class.call
    expect(Badges::AwardStreak).to have_received(:call).with(weeks: 4)
  end
end
