require "rails_helper"

RSpec.describe Search::BulkIndexWorker, type: :worker do
  let(:worker) { subject }
  let(:article) { create(:article) }

  include_examples "#enqueues_on_correct_queue", "high_priority", ["Reaction", 1]

  it "indexes documents for a set of given ids and object class", elasticsearch: "Reaction" do
    reactions = [create(:reaction, reactable: article), create(:reaction), create(:reaction)]
    Sidekiq::Worker.clear_all

    reactions.each do |reaction|
      expect { reaction.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    end
    worker.perform("Reaction", reactions.map(&:id))

    reactions.each do |reaction|
      expect(reaction.elasticsearch_doc.dig("_source", "id")).to eql(reaction.id)
    end
  end
end
