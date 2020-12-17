require "rails_helper"

RSpec.describe "Beta provider access", type: :system do
  let(:providers) { %w[Facebook GitHub Twitter] }
  let(:beta_providers) { ["Apple"] }

  before do
    allow(SiteConfig).to receive(:authentication_providers).and_return(Authentication::Providers.available)
  end

  context "when a user tries to sign_up" do
    it "doesn't render beta providers by default" do
      visit sign_up_path

      providers.each do |name|
        expect(page).to have_button("Continue with #{name}")
      end

      beta_providers.each do |name|
        expect(page).not_to have_button("Continue with #{name}")
      end
    end

    it "renders beta providers when passed in the correct state param" do
      Flipper.enable(:apple_auth)
      visit sign_up_path

      providers.each do |name|
        expect(page).to have_button("Continue with #{name}")
      end

      beta_providers.each do |name|
        expect(page).to have_button("Continue with #{name}")
      end
    end
  end
end
