require "rails_helper"

RSpec.describe Search::BulkIndexWorker, type: :worker do
  let(:worker) { subject }
  let(:article) { create(:article) }

  include_examples "#enqueues_on_correct_queue", "high_priority", ["Tag", 1]

  it "indexes documents for a set of given ids and object class", elasticsearch: "Tag" do
    tags = [create(:tag), create(:tag), create(:tag)]
    Sidekiq::Worker.clear_all

    tags.each do |tag|
      expect { tag.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    end
    worker.perform("Tag", tags.map(&:id))

    tags.each do |tag|
      expect(tag.elasticsearch_doc.dig("_source", "id")).to eql(tag.id)
    end
  end
end
