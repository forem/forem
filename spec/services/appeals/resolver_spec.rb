require "rails_helper"

RSpec.describe Appeals::Resolver do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }
  let(:article) { create(:article, user: user, automod_label: "clear_and_obvious_spam") }
  let(:appeal) { create(:flag_appeal, user: user, appealable: article) }

  let(:mascot) { create(:user) }

  describe ".approve" do
    before do
      allow(Settings::General).to receive(:mascot_user_id).and_return(mascot.id)
      user.add_role(:suspended)
      user.add_role(:spam)
      Reaction.create!(user_id: mascot.id, reactable: article, category: "vomit")
    end

    it "removes suspended/spam roles from user and clears article automod_label" do
      expect(user.spam_or_suspended?).to be true

      described_class.approve(appeal: appeal, admin: admin)

      user.reload
      article.reload
      appeal.reload

      expect(user.spam_or_suspended?).to be false
      expect(article.automod_label).to eq("no_moderation_label")
      expect(appeal.status).to eq("approved")
      expect(appeal.resolved_by).to eq(admin)
      expect(Reaction.exists?(user_id: mascot.id, reactable: article, category: "vomit")).to be false
    end

    it "approves appeal when appealable target is a User profile" do
      user_appeal = create(:flag_appeal, user: user, appealable: user)
      described_class.approve(appeal: user_appeal, admin: admin)

      user.reload
      user_appeal.reload

      expect(user.spam_or_suspended?).to be false
      expect(user_appeal.status).to eq("approved")
    end

    it "approves appeal when appealable target is a Comment and cleans up vomit reactions" do
      comment = create(:comment, user: user, score: -196)
      Reaction.create!(user_id: mascot.id, reactable: comment, category: "vomit")
      comment_appeal = create(:flag_appeal, user: user, appealable: comment)
      allow(Comments::CalculateScoreWorker).to receive(:perform_async)

      described_class.approve(appeal: comment_appeal, admin: admin)

      comment_appeal.reload

      expect(comment_appeal.status).to eq("approved")
      expect(Reaction.exists?(user_id: mascot.id, reactable: comment, category: "vomit")).to be false
      expect(Comments::CalculateScoreWorker).to have_received(:perform_async).with(comment.id)
    end
  end

  describe ".reject" do
    it "marks the appeal as rejected" do
      described_class.reject(appeal: appeal, admin: admin)

      appeal.reload
      expect(appeal.status).to eq("rejected")
      expect(appeal.resolved_by).to eq(admin)
    end
  end
end
