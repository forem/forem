require "rails_helper"

RSpec.describe EmailMessage, type: :model do
  describe "validations" do
    subject { create(:email_message) }

    it { is_expected.to belong_to(:feedback_message).optional }
  end

  describe "#fast_destroy_old_notifications" do
    it "bulk deletes emails older than given timestamp" do
      allow(BulkSqlDelete).to receive(:delete_in_batches)
      described_class.fast_destroy_old_retained_email_deliveries("a_time")
      expect(BulkSqlDelete).to have_received(:delete_in_batches).with(a_string_including("< 'a_time'"))
    end
  end

  describe "#Handles html and non html content" do
    it "return correct content with no html" do
      email_message = create(:email_message, content: "Test")
      expect(email_message.html_content).to eq("Test")
    end

    it "return correct content with html" do
      email_message = create(:email_message, content: "<html>Test</html>")
      expect(email_message.html_content).to eq("<html>Test</html>")
    end

    it "return correct content with nil" do
      email_message = create(:email_message, content: nil)
      expect(email_message.html_content).to eq("")
    end
  end
end
