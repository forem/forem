require "rails_helper"

RSpec.describe Search::ReindexRelatedDocuments, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "high_priority", ["User", 1, "articles"]

  it "raises an error if record is not found" do
    expect { worker.perform("User", 1, "articles") }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "indexes related documents" do
    user = create(:user)
    article = create(:article, user: user)
    expect { article.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    worker.perform(user.class.name, user.id, "articles")

    expect(article.elasticsearch_doc.dig("_source", "id")).to eql(article.search_id)
  end
end
