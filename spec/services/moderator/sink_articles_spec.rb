require "rails_helper"

RSpec.describe Moderator::SinkArticles, type: :service do
  let(:moderator) { create(:user, :trusted) }
  let(:spam_user) do
    user = create(:user)
    create_list(:article, 3, user: user)
    user
  end
  let(:vomit_reaction) { create(:reaction, reactable: spam_user, user: moderator, category: "vomit") }

  describe "#call" do
    it "lowers all of a user's articles' scores by 25 each if not confirmed" do
      vomit_reaction
      expect do
        sidekiq_perform_enqueued_jobs do
          described_class.call(spam_user.id)
        end
      end.to change { spam_user.articles.sum(:score) }.from(0).to(-75)
    end

    it "lowers all of the user's articles' scores by 50 each if confirmed" do
      vomit_reaction.update(status: "confirmed")
      expect do
        sidekiq_perform_enqueued_jobs do
          described_class.call(spam_user.id)
        end
      end.to change { spam_user.articles.sum(:score) }.from(0).to(-150)
    end
  end
end
