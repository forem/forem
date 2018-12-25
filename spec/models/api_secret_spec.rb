require "rails_helper"

RSpec.describe ApiSecret, type: :model do
  describe "validations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_length_of(:description).is_at_least(1).is_at_most(ApiSecret::DESCRIPTION_MAX_LENGTH) }
  end
end
