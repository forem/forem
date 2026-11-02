require "rails_helper"

RSpec.describe "Display articles search spec", :js do
  it "returns correct results for a search" do
    query = "<marquee='alert(document.cookie)'>XSS"
    user = create(:user, :without_profile, profile_image: nil)
    article = create(:article, user: user, with_tags: false)
    create(:comment, user: user, commentable: article, body_markdown: query)

    url_encoded_query = CGI.escape(query)
    visit "/search?q=#{url_encoded_query}&filters=class_name:Comment"

    expect(page.find(".crayons-story__snippet")["innerHTML"])
      .to eq("…<mark>marquee</mark>='<mark>alert</mark>(<mark>document.cookie</mark>)'&gt;<mark>XSS</mark>…")
  end
end
