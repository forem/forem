require "rails_helper"

RSpec.describe "Logo behaviour" do
  let!(:user) { create(:user) }
  let(:resized_logo) { "default.png" }

  before do
    sign_in user
  end

  context "with an image set" do
    before do
      allow(Settings::General).to receive(:resized_logo).and_return(resized_logo)
    end

    it "renders the resized_logo" do
      visit root_path
      within(".site-logo") do
        expect(page.find(".site-logo__img")["src"]).to have_content(resized_logo)
      end
    end
  end

  context "without an image set" do
    before do
      allow(Settings::General).to receive(:resized_logo).and_return(nil)
    end

    it "renders the the community name" do
      visit root_path
      within(".truncate-at-2") do
        expect(page).to have_text("DEV(local)")
      end
    end
  end
end
