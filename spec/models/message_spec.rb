require "rails_helper"

RSpec.describe Message, type: :model do
  describe "validations" do
    subject { build(:message, :ignore_after_callback)}

    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:chat_channel) }
    it { is_expected.to validate_presence_of(:message_html) }
    it { is_expected.to validate_presence_of(:message_markdown) }
  end
end
