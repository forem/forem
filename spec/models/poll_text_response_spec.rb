require "rails_helper"

RSpec.describe PollTextResponse, type: :model do
  let(:poll) { create(:poll, :text_input) }
  let(:user) { create(:user) }
  let(:poll_text_response) { build(:poll_text_response, poll: poll, user: user) }

  describe "validations" do
    subject { create(:poll_text_response, poll: poll, user: user) }

    it { is_expected.to validate_presence_of(:text_content) }
    it { is_expected.to validate_length_of(:text_content).is_at_most(1000) }
    it { is_expected.to validate_uniqueness_of(:poll_id).scoped_to(:user_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:poll) }
    it { is_expected.to belong_to(:user) }
  end

  describe "valid text response" do
    it "is valid with valid attributes" do
      expect(poll_text_response).to be_valid
    end
  end

  describe "invalid text response" do
    it "is invalid without text content" do
      poll_text_response.text_content = nil
      expect(poll_text_response).not_to be_valid
      expect(poll_text_response.errors[:text_content]).to include("can't be blank")
    end

    it "is invalid with text content longer than 1000 characters" do
      poll_text_response.text_content = "a" * 1001
      expect(poll_text_response).not_to be_valid
      expect(poll_text_response.errors[:text_content]).to include("is too long (maximum is 1000 characters)")
    end

    it "prevents duplicate responses from the same user for the same poll" do
      create(:poll_text_response, poll: poll, user: user)
      duplicate_response = build(:poll_text_response, poll: poll, user: user)
      expect(duplicate_response).not_to be_valid
      expect(duplicate_response.errors[:poll_id]).to include("has already been taken")
    end
  end
end
