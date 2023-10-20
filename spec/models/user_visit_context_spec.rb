require "rails_helper"

RSpec.describe UserVisitContext do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:ahoy_visits).class_name("Ahoy::Visit").dependent(:nullify) }
  end

  describe "callbacks" do
    let(:user) { create(:user) }
    let(:user_visit_context) { build(:user_visit_context, user: user) }

    it "calls set_user_language after create" do
      allow(user_visit_context).to receive(:set_user_language)
      user_visit_context.save!
      expect(user_visit_context).to have_received(:set_user_language)
    end
  end

  describe "#set_user_language" do
    let(:user) { create(:user) }
    let(:user_visit_context) { build(:user_visit_context, user: user, accept_language: "en-US;q=0.9,fr-FR;q=0.8") }

    it "creates UserLanguage records" do
      expect { user_visit_context.set_user_language }
        .to change(UserLanguage, :count).by(2)
    end

    it "logs an error if something goes wrong" do
      allow(UserLanguage).to receive(:where).and_raise(StandardError)
      allow(Rails.logger).to receive(:error).with(instance_of(StandardError))
      user_visit_context.set_user_language
      expect(Rails.logger).to have_received(:error).with(instance_of(StandardError))
    end

    it "matches specific languages" do
      user_visit_context.set_user_language
      expect(UserLanguage.pluck(:language)).to match_array(%w[en fr])
    end
  end
end
