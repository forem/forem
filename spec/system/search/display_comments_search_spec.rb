require "rails_helper"

RSpec.describe "Display articles search spec", type: :system, js: true, elasticsearch: "FeedContent" do
  it "returns correct results for a search" do
    query = "<marquee='alert(document.cookie)'>XSS"
    found_comment = create(:comment, body_markdown: query)
    index_documents_for_search_class([found_comment], Search::FeedContent)

    url_encoded_query = CGI.escape(query)
    visit "/search?q=#{url_encoded_query}&filters=class_name:Comment"

    expect(page.find(".crayons-story__snippet")["innerHTML"]).
      to eq("…&lt;<mark>marquee</mark>='<mark>alert</mark>(<mark>document.cookie</mark>)'&gt;<mark>XSS</mark>…")
  end
end
