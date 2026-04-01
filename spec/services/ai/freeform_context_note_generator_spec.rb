require "rails_helper"

RSpec.describe Ai::FreeformContextNoteGenerator, type: :service do
  let(:article) { create(:article) }
  let(:ai_client) { instance_double(Ai::Base) }
  let(:generator) { described_class.new(article) }

  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client)
    # create some comments
    create(:comment, commentable: article, body_markdown: "First comment", score: 10)
    create(:comment, commentable: article, body_markdown: "Second comment", score: 5)
  end

  describe "#call" do
    it "creates a context note when AI returns a concise response" do
      allow(ai_client).to receive(:call).and_return("This framework revolutionizes tech.")

      expect { generator.call }.to change(ContextNote, :count).by(1)

      note = ContextNote.last
      expect(note.article).to eq(article)
      expect(note.body_markdown).to eq("This framework revolutionizes tech.")
      expect(note.tag_id).to be_nil
    end

    it "ignores excessively long responses that exceed sanity threshold" do
      long_response = "A" * 305
      allow(ai_client).to receive(:call).and_return(long_response)

      expect { generator.call }.not_to change(ContextNote, :count)
    end

    it "retries and succeeds when the first response is too long but less than 300" do
      long_response = "A" * 60 # Too long for 50 threshold, but < 300
      short_response = "This framework revolutionizes tech."
      
      allow(ai_client).to receive(:call).and_return(long_response, short_response)

      expect { generator.call }.to change(ContextNote, :count).by(1)
      expect(ai_client).to have_received(:call).twice
    end
    
    it "retries and succeeds when the first response is too short" do
      too_short = "A" * 9
      short_response = "This framework revolutionizes tech."
      
      allow(ai_client).to receive(:call).and_return(too_short, short_response)

      expect { generator.call }.to change(ContextNote, :count).by(1)
      expect(ai_client).to have_received(:call).twice
    end

    it "fails gracefully after max retries" do
      long_response = "A" * 60
      allow(ai_client).to receive(:call).and_return(long_response)

      expect { generator.call }.not_to change(ContextNote, :count)
      expect(ai_client).to have_received(:call).exactly(3).times
    end
  end
end
