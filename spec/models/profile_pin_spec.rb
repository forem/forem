require "rails_helper"

RSpec.describe ProfilePin, type: :model do
  let_it_be(:user) { create(:user) }

  describe "validations" do
    describe "number of pins" do
      let_it_be(:articles) { create_list(:article, 4, user: user) }
      let_it_be(:pins) do
        articles.each { |article| create(:profile_pin, pinnable_id: article.id, profile_id: user.id) }
      end

      let(:fifth_article) { create(:article, user: user) }
      let(:sixth_article) { create(:article, user: user) }

      it "allows up to five pins per user" do
        pin = build(:profile_pin, pinnable_id: fifth_article.id, profile_id: user.id)
        expect(pin).to be_valid
      end

      it "disallows the sixth pin" do
        create(:profile_pin, pinnable_id: fifth_article.id, profile_id: user.id)
        expect do
          create(:profile_pin, pinnable_id: sixth_article.id, profile_id: user.id)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    describe "#profile" do
      let_it_be(:article) { create(:article, user: user) }

      it "ensures pinnable belongs to the same profile" do
        pin = build(:profile_pin, pinnable_id: article.id, profile_id: create(:user).id)
        expect(pin).not_to be_valid
      end

      it "ensures one pin per pinnable per profile" do
        create(:profile_pin, pinnable_id: article.id, profile_id: user.id)
        other_pin = build(:profile_pin, pinnable_id: article.id, profile_id: user.id)
        expect(other_pin).not_to be_valid
      end
    end
  end
end
