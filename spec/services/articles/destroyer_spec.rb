require "rails_helper"

RSpec.describe Articles::Destroyer, type: :service do
  let(:article) { create(:article) }
  let(:event_dispatcher) { double }

  it "destroys an article" do
    described_class.call(article)
    expect(Article.find_by(id: article.id)).to be_nil
  end

  it "destroys an article whose public_reactions_count has drifted below its reactions" do
    create_list(:reaction, 3, reactable: article, category: "like")
    article.update_columns(public_reactions_count: 1)

    described_class.call(article)
    expect(Article.find_by(id: article.id)).to be_nil
  end

  it "schedules removing notifications if there are comments" do
    create(:comment, commentable: article)
    sidekiq_assert_enqueued_with(job: Notifications::RemoveAllWorker) do
      described_class.call(article)
    end
  end
end
