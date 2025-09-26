require "rails_helper"

RSpec.describe "Sidebar Tooltip", type: :system do
  it "has tooltip element with correct attributes" do
    # Create a user and sign in to ensure sidebar is visible
    user = create(:user)
    sign_in user
    
    # Create a root subforem so the sidebar appears
    create(:subforem, root: true, discoverable: true)
    
    visit root_path
    
    # Wait for the page to load and check if sidebar exists
    expect(page).to have_css("#main-side-bar", wait: 10)
    
    # Find the subforems menu item and verify it has the tooltip class and data attribute
    menu_item = find(".crayons-side-nav__item--menu.subforems-menu-tooltip", wait: 10)
    expect(menu_item[:'data-tooltip']).to eq("View all Subforems")
  end
end
