require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210326172701_update_articles_for_tsvector_trigger.rb",
)

describe DataUpdateScripts::UpdateArticlesForTsvectorTrigger do
  # [@rhymes] this test is technically testing a trigger created in
  # the AddTsvectorUpdateTriggerToArticlesTsv migration
  it "updated the tsv column" do
    article = create(:article)
    article.update_columns(tsv: nil)

    described_class.new.run

    expect(article.reload.tsv).to be_present
  end
end
