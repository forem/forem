require "rails_helper"

RSpec.describe Ai::ChatService, type: :service do
  let(:user) { create(:user) }
  let(:ai_client) { instance_double(Ai::Base) }
  let(:service) { described_class.new(user) }

  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client)
  end

  describe "#generate_response" do
    it "calls the AI client with a prompt including user context" do
      create(:article, user: user, title: "My Article", description: "Something I wrote", published: true)

      # Mock page view by creating an article and a page view for it
      viewed_article = create(:article, title: "Viewed Article", description: "Something I read")
      user.page_views.create(article: viewed_article)

      # Mock reading list by creating a reaction
      saved_article = create(:article, title: "Saved Article", description: "Something I saved")
      create(:reaction, user: user, reactable: saved_article, category: "readinglist")

      allow(ai_client).to receive(:call).and_return("Hello human")

      result = service.generate_response("Hi there")

      expect(result[:response]).to eq("Hello human")
      expect(ai_client).to have_received(:call).with(/My Article/)
      expect(ai_client).to have_received(:call).with(/Viewed Article/)
      expect(ai_client).to have_received(:call).with(/Saved Article/)
      expect(ai_client).to have_received(:call).with(/Hi there/)
    end

    it "maintains history" do
      allow(ai_client).to receive(:call).and_return("Response 1", "Response 2")

      service.generate_response("Message 1")
      result = service.generate_response("Message 2")

      expect(result[:history].length).to eq(4) # 2 pairs of user/assistant
      expect(result[:history].last[:text]).to eq("Response 2")
    end
  end
end
