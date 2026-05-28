require "rails_helper"

RSpec.describe Articles::ReprocessByImageHostWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "low_priority", ["cdn.example.com"]

  describe "#perform" do
    it "is a no-op for a blank host" do
      expect(Article).not_to receive(:where)
      worker.perform("")
    end

    it "re-evaluates only articles whose processed_html references the host" do
      host = "cdn.hashnode.com"
      matching = create(:article)
      non_matching = create(:article)
      matching.update_column(:processed_html, %(<p><img src="https://#{host}/foo.png"></p>))
      non_matching.update_column(:processed_html, "<p>nothing to see</p>")

      touched_ids = []
      allow_any_instance_of(Article).to receive(:evaluate_and_update_column_from_markdown) do |article|
        touched_ids << article.id
      end
      allow_any_instance_of(Article).to receive(:async_bust)

      worker.perform(host)

      expect(touched_ids).to contain_exactly(matching.id)
    end

    it "respects a positive limit" do
      host = "cdn.hashnode.com"
      3.times do
        a = create(:article)
        a.update_column(:processed_html, %(<img src="https://#{host}/x.png">))
      end

      touched = 0
      allow_any_instance_of(Article).to receive(:evaluate_and_update_column_from_markdown) { touched += 1 }
      allow_any_instance_of(Article).to receive(:async_bust)

      worker.perform(host, 2)

      expect(touched).to eq(2)
    end
  end
end
