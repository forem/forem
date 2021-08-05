require "rails_helper"

RSpec.describe "Display articles search spec", type: :system, js: true do
  it "returns correct results for a search" do
    found_article_one = create(:article)
    found_article_one.update_columns(cached_tag_list: "ruby")
    found_article_two = create(:article)
    found_article_two.update_columns(body_markdown: "#{found_article_two.body_markdown} Ruby Tuesday")
    not_found_article = create(:article)

    visit "/search?q=ruby&filters=class_name:Article"

    expect(page).to have_content(found_article_one.title)
    expect(page).to have_content(found_article_two.title)
    expect(page).not_to have_content(not_found_article.title)
  end

  it "returns all expected article fields" do
    found_article_one = create(:article)
    found_article_one.update_columns(cached_tag_list: "ruby",
                                     reading_time: 5,
                                     comments_count: 2,
                                     public_reactions_count: 3)
    visit "/search?q=ruby&filters=class_name:Article"

    expect(page).to have_content(found_article_one.title)
    expect(find("#article-link-#{found_article_one.id}")["href"]).to include(found_article_one.path)
    expect(page).to have_selector("button[data-reactable-id=\"#{found_article_one.id}\"]")
    expect(page).to have_content("5 min read")
    expect(find_link("#ruby")["href"]).to include("/t/ruby")
    expect(find_link(found_article_one.user.name)["href"]).to include(found_article_one.username)
    expect(page).to have_content("3 reactions")
    expect(page).to have_content("2 comments")
  end

  it "does not show reaction data if article has no reactions" do
    found_article_one = create(:article)
    found_article_one.update_columns(cached_tag_list: "ruby", public_reactions_count: 0)
    visit "/search?q=ruby&filters=class_name:Article"

    expect(page).not_to have_content("0 reactions")
  end
end
