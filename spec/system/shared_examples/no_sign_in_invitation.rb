RSpec.shared_examples "no sign_in invitation" do
  it "no sign_in invitation", js: true do
    within("#substories") do
      expect(page).not_to have_content("Sign in to customize your feed")
      expect(page).not_to have_link("TWITTER")
      expect(page).not_to have_link("GITHUB")
    end
  end
end
