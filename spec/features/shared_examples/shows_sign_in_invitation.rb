RSpec.shared_examples "shows the sign_in invitation" do
  it "shows the sign_in invitation", js: true do
    within("#substories") do
      expect(page).to have_content("Sign in to customize your feed")
      expect(page).to have_link("TWITTER")
      expect(page).to have_link("GITHUB")
    end
  end
end
