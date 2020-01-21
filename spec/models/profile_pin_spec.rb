require "rails_helper"

RSpec.describe ProfilePin, type: :model do
  let_it_be(:user) { create(:user) }

  describe "validations" do
    describe "number of pins" do
      let_it_be(:articles) { create_list(:article, 4, user: user) }
      let_it_be(:pins) do
        articles.each { |article| create(:profile_pin, pinnable: article, profile: user) }
      end

      let(:fifth_article) { create(:article, user: user) }
      let(:sixth_article) { create(:article, user: user) }

      it "allows up to five pins per user" do
        pin = build(:profile_pin, pinnable: fifth_article, profile: user)
        expect(pin).to be_valid
      end

      it "disallows the sixth pin" do
        create(:profile_pin, pinnable: fifth_article, profile: user)
        user.reload
        expect do
          create(:profile_pin, pinnable: sixth_article, profile: user)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    describe "#profile" do
      let_it_be(:article) { create(:article, user: user) }

      it "ensures pinnable belongs to the same profile" do
        pin = build(:profile_pin, pinnable: article, profile: create(:user))
        expect(pin).not_to be_valid
      end

      it "ensures one pin per pinnable per profile" do
        create(:profile_pin, pinnable: article, profile: user)
        other_pin = build(:profile_pin, pinnable: article, profile: user)
        expect(other_pin).not_to be_valid
      end
    end
  end
end
