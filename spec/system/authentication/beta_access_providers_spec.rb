require "rails_helper"

RSpec.describe "Beta provider access", type: :system do
  let(:providers) { %w[Facebook GitHub Twitter] }
  let(:beta_providers) { ["Apple"] }

  context "when a user tries to sign_up" do
    it "doesn't render beta providers by default" do
      visit sign_up_path

      providers.each do |name|
        expect(page).to have_link("Continue with #{name}")
      end

      beta_providers.each do |name|
        expect(page).not_to have_link("Continue with #{name}")
      end
    end

    it "renders beta providers when passed in the correct state param" do
      visit sign_up_path(state: "beta_providers_enabled")

      providers.each do |name|
        expect(page).to have_link("Continue with #{name}")
      end

      beta_providers.each do |name|
        expect(page).to have_link("Continue with #{name}")
      end
    end
  end
end
