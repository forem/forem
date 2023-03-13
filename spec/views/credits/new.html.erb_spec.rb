require "rails_helper"

RSpec.describe "credits/new" do
  let(:purchaser) { create(:user) }
  let(:credit) { build(:credit) }

  before do
    assign(:purchaser, purchaser)
    assign(:credit, credit)

    sign_in purchaser
  end

  it "shows the page for light mode by default" do
    render

    expect(rendered).to have_content("color: '#32325d'")
  end

  it "respects dark mode if set" do
    purchaser.setting.update(config_theme: :dark_theme)

    render

    expect(rendered).to have_content("color: 'white'")
  end

  it "renders localized submitting message in js correctly" do
    render

    expect(rendered).to have_content("changeSubmitButton({ text: 'Submitting...', active: false })")
    expect(rendered).to have_content("changeSubmitButton({ text: 'Complete Purchase', active: true })")
  end
end
