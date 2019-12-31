require "rails_helper"

RSpec.describe SortableCount, type: :model do
  let(:article) { create(:article, featured: true) }

  it "creates title" do
    count = described_class.find_or_create_by(countable_id: article.id, countable_type: "Article", slug: "published_articles_this_7_days")
    count.update_column(:number, 1)
    expect(count.title).to eq("Published Articles This 7 Days")
  end
end
