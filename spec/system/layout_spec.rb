require "rails_helper"

RSpec.describe "Layout", type: :system do
  context "when rendering the footer" do
    it "displays navigation links for public Forems" do
      allow(ForemInstance).to receive(:private?).and_return(false)
      visit root_path
      expect(page).to have_selector("footer nav")
    end

    it "does not display navigation links for private Forems" do
      allow(ForemInstance).to receive(:private?).and_return(true)
      visit root_path
      expect(page).not_to have_selector("footer nav")
    end
  end
end
