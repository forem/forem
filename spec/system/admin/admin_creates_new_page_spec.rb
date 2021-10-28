require "rails_helper"

RSpec.describe "Admin creates new page", type: :system do
  let(:admin) { create(:user, :super_admin) }

  context "when we pass through a slug param" do
    before do
      allow(ForemInstance).to receive(:private?).and_return(true)
      sign_in admin
      visit new_admin_page_path(slug: "code-of-conduct")
    end

    it "will pre-populate the fields correctly" do
      expect(find_field("page[title]").value).to eq("Code of Conduct")
      expect(find_field("page[slug]").value).to eq("code-of-conduct")
      expect(find_field("page[is_top_level_path]").value).to eq("1")
      expect(find_field("page[landing_page]").value).to eq("1")

      text = "All participants of #{community_name} are expected to abide by our Code of Conduct"
      expect(find_field("page[body_html]").value).to include(text)
    end
  end
end
