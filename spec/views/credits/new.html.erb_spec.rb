require "rails_helper"

RSpec.describe "credits/new", type: :view do
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
end
