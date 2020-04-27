require "rails_helper"

RSpec.describe "users/edit", type: :view do
  let(:user) { create(:user) }

  context "when on profile edit" do
    before do
      assign(:tab, "profile")
      assign(:user, user)
      assign(:tab_list, user.settings_tab_list)
      allow(view).to receive(:current_user).and_return(user)
    end

    it "asks user to connect with github when it's missing" do
      create(:identity, user: user, provider: "twitter")

      render
      expect(rendered).to match(/Connect GitHub Account/)
      expect(rendered).not_to match(/Connect Twitter Account/)
    end

    it "asks user to connect with twitter if it's missing" do
      create(:identity, user: user, provider: "github")

      render
      expect(rendered).to match(/Connect Twitter Account/)
      expect(rendered).not_to match(/Connect GitHub Account/)
    end
  end
end
