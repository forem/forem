require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200217131245_re_index_existing_articles_with_approved.rb")

describe DataUpdateScripts::ReIndexExistingArticlesWithApproved do
  it "triggers a re-index on articles" do
    expect(Article).to respond_to(:trigger_index)
  end
end
