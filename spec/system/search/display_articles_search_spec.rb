require "rails_helper"

RSpec.describe "Display articles search spec", :js do
  it "returns correct results, expected article fields, and hides zero reactions", :aggregate_failures do
    author = create(:user, :without_profile, profile_image: nil, name: "Search Author")
    found_article_one = create(:article, user: author, with_tags: false)
    found_article_one.update_columns(cached_tag_list: "ruby",
                                     reading_time: 5,
                                     comments_count: 2,
                                     public_reactions_count: 3)
    found_article_two = create(:article, user: author, with_tags: false)
    found_article_two.update_columns(body_markdown: "#{found_article_two.body_markdown} Ruby Tuesday",
                                     public_reactions_count: 0)
    not_found_article = create(:article, user: author, with_tags: false)

    visit "/search?q=ruby&filters=class_name:Article"

    expect(page).to have_content(found_article_one.title)
    expect(page).to have_content(found_article_two.title)
    expect(page).to have_no_content(not_found_article.title)
    expect(find("#article-link-#{found_article_one.id}")["href"]).to include(found_article_one.path)
    expect(page).to have_no_css("button[data-reactable-id=\"#{found_article_one.id}\"]")
    expect(page).to have_content("5 min read")
    expect(find_link("#ruby")["href"]).to include("/t/ruby")
    expect(page).to have_content("3 reactions")
    expect(page).to have_content("2 comments", normalize_ws: true)
    expect(page).to have_no_content("0 reactions")
  end
end
