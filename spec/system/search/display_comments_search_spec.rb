require "rails_helper"

RSpec.describe "Display articles search spec", type: :system, js: true do
  it "returns correct results for a search" do
    query = "<marquee='alert(document.cookie)'>XSS"
    create(:comment, body_markdown: query)

    url_encoded_query = CGI.escape(query)
    visit "/search?q=#{url_encoded_query}&filters=class_name:Comment"

    expect(page.find(".crayons-story__snippet")["innerHTML"])
      .to eq("…<mark>marquee</mark>='<mark>alert</mark>(<mark>document.cookie</mark>)'&gt;<mark>XSS</mark>…")
  end
end
