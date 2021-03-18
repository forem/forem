require "rails_helper"

RSpec.describe Moderator::SinkArticles, type: :service do
  let(:moderator) { create(:user, :trusted) }
  let(:spam_user) do
    user = create(:user)
    create_list(:article, 3, user: user)
    user
  end
  let(:scores) { -> { spam_user.articles.reload.pluck(:score) } }
  let(:vomit_reaction) { create(:reaction, reactable: spam_user, user: moderator, category: "vomit") }

  describe "#call" do
    it "lowers all of a user's articles' scores by 25 each if not confirmed" do
      vomit_reaction
      expect do
        sidekiq_perform_enqueued_jobs do
          described_class.call(spam_user.id)
        end
      end.to change(scores, :call).from([0, 0, 0]).to([-25, -25, -25])
    end

    it "lowers all of the user's articles' scores by 50 each if confirmed" do
      vomit_reaction.update(status: "confirmed")
      expect do
        sidekiq_perform_enqueued_jobs do
          described_class.call(spam_user.id)
        end
      end.to change(scores, :call).from([0, 0, 0]).to([-50, -50, -50])
    end

    context "when removing a user vomit reaction" do
      before do
        # pretend we had a confirmed vomit on the user
        spam_user.articles.update(score: -50)
      end

      it "raises all of the user's articles but the moderation score" do
        expect do
          sidekiq_perform_enqueued_jobs do
            described_class.call(spam_user.id)
          end
        end.to change(scores, :call).from([-50, -50, -50]).to([0, 0, 0])
      end
    end
  end
end
