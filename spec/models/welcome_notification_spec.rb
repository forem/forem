require "rails_helper"

RSpec.describe WelcomeNotification, type: :model do
  it { is_expected.to have_many(:notifications) }
  it { is_expected.to have_one(:broadcast) }
  it { is_expected.to validate_presence_of(:cta_text) }
  it { is_expected.to validate_presence_of(:cta_url) }
  it { is_expected.to validate_presence_of(:headline) }
end
