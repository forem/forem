require "rails_helper"

RSpec.describe Ai::CommentCheck, type: :service do
  let(:article) { create(:article) }
  let(:comment) { create(:comment, commentable: article, body_markdown: "Great post, thanks for sharing!") }
  let(:ai_client) { instance_double(Ai::Base) }

  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client)
  end

  describe "#spam? with Gemini (default)" do
    it "returns true when the AI answers YES" do
      allow(ai_client).to receive(:call).and_return("YES")

      expect(described_class.new(comment).spam?).to be(true)
    end

    it "returns false when the AI answers NO" do
      allow(ai_client).to receive(:call).and_return("NO")

      expect(described_class.new(comment).spam?).to be(false)
    end
  end

  describe "#spam? with Jev selected" do
    before { enable_jev_for(:comment_spam_check) }

    it "sends the post and comment as structured state instead of calling Gemini" do
      requests = stub_jev(genuine_reply: 0.9)

      expect(described_class.new(comment).spam?).to be(false)
      expect(Ai::Base).not_to have_received(:new)
      expect(requests.first[:state]).to include(comment: comment.body_markdown)
      expect(requests.first[:state][:post]).to include(title: article.title)
    end

    it "flags a promotional link slipped into an on-topic reply" do
      stub_jev(inserted_link: 0.9, genuine_reply: 0.95)

      expect(described_class.new(comment).spam?).to be(true)
    end

    it "flags clear off-topic promotion" do
      stub_jev(off_context_promotion: 0.9, genuine_reply: 0.1)

      expect(described_class.new(comment).spam?).to be(true)
    end

    it "does not flag an advertisement-like signal on a genuine reply" do
      stub_jev(advertisement: 0.9, genuine_reply: 0.9)

      expect(described_class.new(comment).spam?).to be(false)
    end

    it "uses history only to confirm a comment that already looks spammy" do
      create(:comment, user: comment.user, commentable: create(:article), body_markdown: "Buy cheap followers here")

      stub_jev(repetitive_promotion: 0.95, advertisement: 0.1)
      expect(described_class.new(comment).spam?).to be(false)

      stub_jev(repetitive_promotion: 0.95, advertisement: 0.6)
      expect(described_class.new(comment).spam?).to be(true)
    end
  end
end
