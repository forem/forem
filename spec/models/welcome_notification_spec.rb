require "rails_helper"

RSpec.describe WelcomeNotification, type: :model do
  it { is_expected.to have_many(:notifications) }
  it { is_expected.to have_one(:broadcast) }
end
