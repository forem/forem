require "rails_helper"

RSpec.describe Users::Suspended, type: :model do
  describe "validations" do
    subject { create(:suspended_user) }

    it { is_expected.to validate_presence_of(:username_hash) }
    it { is_expected.to validate_uniqueness_of(:username_hash) }
  end
end
