require "rails_helper"

RSpec.describe "credits/new", type: :view do
  let(:purchaser) { create(:user) }
  let(:credit) { build(:credit) }

  before do
    assign(:purchaser, purchaser)
    assign(:credit, credit)

    sign_in purchaser
  end

  it "shows the page" do
    render
  end
end
