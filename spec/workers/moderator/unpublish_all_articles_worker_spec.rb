require "rails_helper"

RSpec.describe Moderator::UnpublishAllArticlesWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "medium_priority", 1
  it "unpublishes all articles" do
    user = create(:user)
    create_list(:article, 3, user: user)
    expect { described_class.new.perform(user.id) }.to change { user.articles.published.size }.from(3).to(0)
  end

  it "applies proper frontmatter", :aggregate_failures do
    user = create(:user)
    create_list(:article, 3, user: user)
    described_class.new.perform(user.id)
    expect(Article.last.body_markdown).to include("published: false")
    expect(Article.last.body_markdown).not_to include("published: true")
  end
end
