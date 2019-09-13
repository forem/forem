require "rails_helper"

RSpec.describe ProfilePin, type: :model do
  let(:user) { create(:user) }
  let(:second_user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:second_article) { create(:article, user_id: user.id) }
  let(:third_article) { create(:article, user_id: user.id) }
  let(:fourth_article) { create(:article, user_id: user.id) }
  let(:fifth_article) { create(:article, user_id: user.id) }
  let(:sixth_article) { create(:article, user_id: user.id) }

  describe "validations" do
    it "allows up to five pins per user" do
      create(:profile_pin, pinnable_id: article.id, profile_id: user.id)
      create(:profile_pin, pinnable_id: second_article.id, profile_id: user.id)
      create(:profile_pin, pinnable_id: third_article.id, profile_id: user.id)
      create(:profile_pin, pinnable_id: fourth_article.id, profile_id: user.id)
      last_pin = create(:profile_pin, pinnable_id: fifth_article.id, profile_id: user.id)
      expect(last_pin).to be_valid
    end

    it "disallows the sixth pin" do
      create(:profile_pin, pinnable_id: article.id, profile_id: user.id)
      create(:profile_pin, pinnable_id: second_article.id, profile_id: user.id)
      create(:profile_pin, pinnable_id: third_article.id, profile_id: user.id)
      create(:profile_pin, pinnable_id: fourth_article.id, profile_id: user.id)
      create(:profile_pin, pinnable_id: fifth_article.id, profile_id: user.id)
      expect do
        create(:profile_pin, pinnable_id: sixth_article.id, profile_id: user.id)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "ensures pinnable belongs to profile" do
      pin = build(:profile_pin, pinnable_id: article.id, profile_id: second_user.id)
      expect(pin).not_to be_valid
    end

    it "ensures one pin per pinnable per profile" do
      create(:profile_pin, pinnable_id: article.id, profile_id: user.id)
      last_pin = build(:profile_pin, pinnable_id: article.id, profile_id: user.id)
      expect(last_pin).not_to be_valid
    end
  end
end
