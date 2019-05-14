require "rails_helper"

RSpec.describe Comments::CreateIdCodeJob, type: :job do
  describe "#perform_now" do
    let(:article) { FactoryBot.create(:article) }
    let(:comment) { FactoryBot.create(:comment, commentable: article) }

    it "creates an id code" do
      described_class.perform_now(comment.id) do
        expect(comment.id_code).to eql(comment.id.to_s(26))
      end
    end
  end
end
