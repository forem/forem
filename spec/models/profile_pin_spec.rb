require "rails_helper"

RSpec.describe ProfilePin do
  let(:user) { create(:user) }

  describe "validations" do
    describe "number of pins" do
      let(:articles) { create_list(:article, 4, user: user) }
      let(:pins) do
        articles.each { |article| create(:profile_pin, pinnable: article, profile: user) }
      end
      let(:fifth_article) { create(:article, user: user) }
      let(:sixth_article) { create(:article, user: user) }

      before { pins }

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
      let(:article) { create(:article, user: user) }

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

    describe "organization profiles" do
      let(:organization) { create(:organization) }
      let(:org_article) { create(:article, organization: organization, user: user) }

      it "allows an organization to pin an article it owns" do
        pin = build(:profile_pin, pinnable: org_article, profile: organization, profile_type: "Organization")
        expect(pin).to be_valid
      end

      it "disallows pinning an article that does not belong to the organization" do
        other_article = create(:article, user: user)
        pin = build(:profile_pin, pinnable: other_article, profile: organization, profile_type: "Organization")
        expect(pin).not_to be_valid
      end

      it "allows up to five pins per organization" do
        articles = create_list(:article, 5, organization: organization, user: user)
        articles.first(4).each do |article|
          create(:profile_pin, pinnable: article, profile: organization, profile_type: "Organization")
        end
        organization.reload
        pin = build(:profile_pin, pinnable: articles.last, profile: organization, profile_type: "Organization")
        expect(pin).to be_valid
      end

      it "disallows the sixth pin for an organization" do
        articles = create_list(:article, 6, organization: organization, user: user)
        articles.first(5).each do |article|
          create(:profile_pin, pinnable: article, profile: organization, profile_type: "Organization")
        end
        organization.reload
        expect do
          create(:profile_pin, pinnable: articles.last, profile: organization, profile_type: "Organization")
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
