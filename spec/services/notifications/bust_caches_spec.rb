require "rails_helper"

RSpec.describe Notifications::BustCaches, type: :service do
  let(:article) { create(:article) }
  let(:comment) { create(:comment) }
  let(:user) { create(:user) }

  context "when given a notifiable_id and notifiable_type" do
    it "can find a valid notifiable" do
      buster = described_class.new(user: user,
                                   notifiable_id: article.id,
                                   notifiable_type: "Article")
      expect(buster.notifiable).to eq(article)

      buster = described_class.new(user: user,
                                   notifiable_id: comment.id,
                                   notifiable_type: "Comment")
      expect(buster.notifiable).to eq(comment)
    end

    it "raises with an invalid type" do
      buster = described_class.new(user: user,
                                   notifiable_id: article.id,
                                   notifiable_type: "Monkey")
      expect { buster.notifiable }.to raise_error(KeyError)
    end

    it "raises with an invalid id" do
      buster = described_class.new(user: user,
                                   notifiable_id: "1234567",
                                   notifiable_type: "Article")
      expect { buster.notifiable }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
