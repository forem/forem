require "rails_helper"

describe "giveaways/edit.html.erb", type: :view do
  let(:user) { create(:user) }
  let(:current_user) { create(:user, onboarding_package_requested: false) }

  def assign_user_and_errors
    assign(:user, current_user)
    assign(:errors, [])
    allow(view).to receive(:current_user).and_return(current_user)
  end

  context "when user is not logged-in" do
    it "displays twitter log-in option" do
      render
      expect(rendered).to have_selector(:link_or_button, "Sign in with Twitter")
    end

    it "displays github log-in option" do
      render
      expect(rendered).to have_selector(:link_or_button, "Sign in with Github")
    end
  end

  context "when user is logged-in and not already onboard" do
    it "tells user it's over" do
      allow(view).to receive(:current_user).and_return(current_user)
      render
      expect(rendered).to have_text("It seems you've never requested stickers")
    end
  end

  context "when user is logged-in and already onboard" do
    it "allows user to re-apply" do
      current_user.onboarding_package_requested = true
      assign_user_and_errors
      render
      expect(rendered).to render_template(partial: "_form")
    end
  end

  context "when user is logged-in, already onboarded, and already re-requested" do
    it "allows user to re-apply" do
      current_user.onboarding_package_requested = true
      current_user.onboarding_package_requested_again = true
      assign_user_and_errors
      render
      expect(rendered).to have_text("stickers should arrive soon")
    end
  end
end
