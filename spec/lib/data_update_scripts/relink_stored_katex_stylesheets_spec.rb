require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20261025160000_relink_stored_katex_stylesheets.rb")

describe DataUpdateScripts::RelinkStoredKatexStylesheets do
  let(:current_path) { URI.parse(ActionController::Base.helpers.asset_path("katex.css")).path }
  let(:stale_html) do
    %(<link rel="stylesheet" href="https://example.com/assets/katex-#{'a' * 64}.css" /><p>math</p>)
  end

  it "points stored KaTeX stylesheet links in articles, comments and events at the current digest" do
    article = create(:article)
    comment = create(:comment, commentable: article)
    event = create(:event)
    article.update_column(:processed_html, stale_html)
    comment.update_column(:processed_html, stale_html)
    event.update_column(:processed_html, stale_html)

    described_class.new.run

    expected = %(<link rel="stylesheet" href="https://example.com#{current_path}" /><p>math</p>)
    expect(article.reload.processed_html).to eq(expected)
    expect(comment.reload.processed_html).to eq(expected)
    expect(event.reload.processed_html).to eq(expected)
  end

  it "leaves processed_html without a KaTeX stylesheet link untouched" do
    article = create(:article)
    original = article.processed_html

    expect { described_class.new.run }.not_to(change { article.reload.processed_html })
    expect(original).not_to include("katex-")
  end
end
