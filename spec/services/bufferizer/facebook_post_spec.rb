require "rails_helper"

RSpec.describe Bufferizer::FacebookPost, type: :service do
  describe "#call" do
    let(:user) { create(:user) }
    let(:tag) { create(:tag, buffer_profile_id_code: "test") }
    let(:article) { create(:article, user_id: user.id, tags: tag.name) }

    context "when article is nil" do
      it "doesn't raise an error" do
        post = "test post"
        expect { described_class.call(nil, post, user.id) }.not_to raise_error
      end
    end

    context "when post is nil" do
      it "doesn't raise an error" do
        expect { described_class.call(article, nil, user.id) }.not_to raise_error
      end
    end

    context "when admin_id is nil" do
      it "doesn't raise an error" do
        post = "test post"
        expect { described_class.call(article, post, nil) }.not_to raise_error
      end
    end

    it "sends to buffer facebook" do
      post = "test facebook post"
      described_class.call(article, post, user.id)
      expect(article.facebook_last_buffered.utc.to_i).to be > 2.minutes.ago.to_i
    end

    it "adds linkedin social tags" do
      post = "test facebook post"
      described_class.call(article, post, user.id)
      expect(BufferUpdate.last.body_text).to include(" #programming")
      expect(BufferUpdate.last.body_text).to include(" ##{article.tag_list.first}")
    end
  end
end
