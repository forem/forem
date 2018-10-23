# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
require "rails_helper"

RSpec.describe Reaction, type: :model do
  let(:user)        { create(:user) }
  let(:author)      { create(:user) }
  let(:article)     { create(:article, user_id: author.id, featured: true) }
  let(:comment) do
    create(:comment, user_id: user.id, commentable_id: article.id, commentable_type: "Article")
  end
  let(:reaction) do
    build(:reaction, user_id: user.id, reactable_id: comment.id, reactable_type: "Comment")
  end

  describe "validations" do
    it "allows like reaction for users without trusted role" do
      reaction.category = "like"
      expect(reaction).to be_valid
    end

    it "does not allow reactions outside of whitelist" do
      reaction.category = "woozlewazzle"
      expect(reaction).not_to be_valid
    end

    it "does not allow vomit reaction for users without trusted role" do
      reaction.category = "vomit"
      expect(reaction).not_to be_valid
    end

    it "does not allow thumbsdown reaction for users without trusted role" do
      reaction.category = "thumbsdown"
      expect(reaction).not_to be_valid
    end

    it "does not allow reaction on unpublished article" do
      reaction = build(
        :reaction, user_id: user.id, reactable_id: article.id, reactable_type: "Article"
      )
      expect(reaction).to be_valid
      article.update_column(:published, false)
      reaction = build(
        :reaction, user_id: user.id, reactable_id: article.id, reactable_type: "Article"
      )
      expect(reaction).not_to be_valid
    end

    context "when user is trusted" do
      before { user.add_role(:trusted) }

      it "allows vomit reactions for users with trusted role" do
        reaction.category = "vomit"
        expect(reaction).to be_valid
      end

      it "allows thumbsdown reactions for users with trusted role" do
        reaction.category = "thumbsdown"
        expect(reaction).to be_valid
      end
    end
  end

  describe "async callbacks" do
    it "runs async jobs effectively" do
      u2 = create(:user)
      c2 = create(:comment, commentable_id: article.id)
      create(:reaction, user_id: u2.id, reactable_id: c2.id, reactable_type: "Comment")
      create(:reaction, user_id: u2.id, reactable_id: article.id, reactable_type: "Article")
      expect(reaction).to be_valid
    end
  end

  describe "#activity_object" do
    it "returns self" do
      expect(reaction.activity_object.instance_of?(described_class)).to be true
    end
  end

  describe "#activity_target" do
    it "returns the porper string" do
      expect(reaction.activity_target).to eq("#{reaction.reactable_type}_#{reaction.reactable_id}")
    end
  end

  describe "stream" do
    after { StreamRails.enabled = false }

    before do
      StreamRails.enabled = true
      allow(StreamNotifier).to receive(:new).and_call_original
    end

    it "notifies the reactable author" do
      create(:reaction, user_id: user.id, reactable_id: article.id, reactable_type: "Article")
      expect(StreamNotifier).to have_received(:new).with(author.id).at_least(:once)
    end
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
