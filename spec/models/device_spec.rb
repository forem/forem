require "rails_helper"

RSpec.describe Device, type: :model do
  let(:device) { create(:device) }

  describe "validations" do
    subject { device }

    describe "builtin validations" do
      it { is_expected.to belong_to(:consumer_app) }
      it { is_expected.to belong_to(:user) }

      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_uniqueness_of(:token).scoped_to(%i[user_id platform consumer_app_id]) }
    end
  end
end
