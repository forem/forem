require "rails_helper"

RSpec.describe EmailMessage, type: :model do
  describe "validations" do
    subject { create(:email_message) }

    it { is_expected.to belong_to(:feedback_message).optional }
  end
end
