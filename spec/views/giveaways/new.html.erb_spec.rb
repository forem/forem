require "rails_helper"

describe "giveaways/new.html.erb", type: :view do
  let(:user) { create(:user) }

  it "thanks users for participating" do
    render
    expect(rendered).to have_text("dev.to's sticker give-away campaign is officially over.")
  end

  it "has link to edit page" do
    render
    # this is a relatively weak test
    expect(rendered).to have_link "here", href: "/freestickers/edit"
  end

  it "has link to the article" do
    render
    expect(rendered).to have_link "process", href: "https://dev.to/thepracticaldev/sending-100-thousand-stickers"
  end
end
