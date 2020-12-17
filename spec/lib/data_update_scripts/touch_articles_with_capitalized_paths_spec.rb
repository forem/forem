require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201209134953_touch_articles_with_capitalized_paths.rb",
)

describe DataUpdateScripts::TouchArticlesWithCapitalizedPaths do
  it "updates articles with a capitalized path" do
    # Populate at least 5 articles
    create_list(:article, 5)

    # Create 1 article with a capitalized path
    bad_article = create(:article, published: true)
    new_path = bad_article.path.titleize.split(" ").join("-")
    bad_article.update_columns(path: new_path) # bypass callback fix

    # Check to make sure the query only catches the article with a bad path
    expect(Article.where("path != lower(path)").count).to eq(1)

    # Run the script
    described_class.new.run

    # Make sure we no longer have any Articles with bad paths
    expect(Article.where("path != lower(path)").count).to eq(0)
  end
end
