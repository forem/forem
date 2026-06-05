require "rails_helper"

RSpec.describe Concepts::ClassifyRecordWorker, type: :worker do
  let(:article) { create(:article, semantic_embedding: Array.new(768, 0.1)) }
  let(:comment) { create(:comment, semantic_embedding: Array.new(768, 0.1)) }

  it "calls the Concepts::Classifier service for articles" do
    classifier_double = instance_double(Concepts::Classifier)
    allow(Concepts::Classifier).to receive(:new).with(article).and_return(classifier_double)
    expect(classifier_double).to receive(:call)

    described_class.new.perform("Article", article.id)
  end

  it "calls the Concepts::Classifier service for comments" do
    classifier_double = instance_double(Concepts::Classifier)
    allow(Concepts::Classifier).to receive(:new).with(comment).and_return(classifier_double)
    expect(classifier_double).to receive(:call)

    described_class.new.perform("Comment", comment.id)
  end

  it "does not classify unpublished articles" do
    unpublished_article = create(:article, published: false, semantic_embedding: Array.new(768, 0.1))
    expect(Concepts::Classifier).not_to receive(:new)

    described_class.new.perform("Article", unpublished_article.id)
  end

  it "does not constantize or process unsupported class names" do
    expect(Concepts::Classifier).not_to receive(:new)
    described_class.new.perform("User", 1)
  end
end
