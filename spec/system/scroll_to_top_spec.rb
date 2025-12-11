require "rails_helper"

RSpec.describe "Scroll to Top Button", type: :system, js: true do
  let(:user) { create(:user) }

  before do
    create_list(:article, 10, user: user, approved: true)
    visit root_path
  end

  it "button exists and is initially hidden" do
    expect(page).to have_css("#back-to-top-btn.hidden", visible: :all)
  end

  it "shows button when scrolling down and hides when scrolling up" do
    page.execute_script("window.scrollTo(0, 500)")
    page.execute_script("window.dispatchEvent(new Event('scroll'))")
    sleep 0.5

    expect(page).to have_css("#back-to-top-btn:not(.hidden)", visible: true)

    page.execute_script("window.scrollTo(0, 0)")
    page.execute_script("window.dispatchEvent(new Event('scroll'))")
    sleep 0.5

    expect(page).to have_css("#back-to-top-btn.hidden", visible: :all)
  end

  it "scrolls to top when button is clicked" do
    page.execute_script("window.scrollTo(0, 1000)")
    page.execute_script("window.dispatchEvent(new Event('scroll'))")
    sleep 0.5

    page.execute_script("document.getElementById('back-to-top-btn').classList.remove('hidden')")
    
    find("#back-to-top-btn").click
    sleep 1

    scroll_position = page.evaluate_script("window.scrollY")
    expect(scroll_position).to be < 100
  end
end
