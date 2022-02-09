require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220209110134_reprocess_user_subscription_liquid_tag_posts.rb",
)

describe DataUpdateScripts::ReprocessUserSubscriptionLiquidTagPosts do
  it "reprocesses HTML for an article with a user_subscription liquid tag" do
    article = create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: true)
    article.update_column(:processed_html, "<p>something</p>")

    expect do
      described_class.new.run
    end.to change { article.reload.processed_html }
  end

  it "does not reprocess HTML for an article without user_subscription liquid tag" do
    article = create(:article, :with_user_subscription_tag_role_user, with_user_subscription_tag: false)
    article.update_column(:processed_html, "<p>something</p>")

    expect do
      described_class.new.run
    end.not_to change { article.reload.processed_html }
  end

  it "does not reprocess HTML for an article if user no longer has authorisation" do
    author = create(:user)
    allow(author).to receive(:has_role?).with(:restricted_liquid_tag, LiquidTags::UserSubscriptionTag).and_return(true)
    article = create(:article, user: author, with_user_subscription_tag: true)
    article.update_column(:processed_html, "<p>something</p>")

    # Remove permission to create posts with this tag
    allow(author).to receive(:has_role?).with(:restricted_liquid_tag, LiquidTags::UserSubscriptionTag).and_return(false)

    expect do
      described_class.new.run
    end.not_to change { article.reload.processed_html }
  end
end
