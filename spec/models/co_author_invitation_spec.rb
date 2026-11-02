require "rails_helper"

RSpec.describe CoAuthorInvitation do
  let(:author) { create(:user) }
  let(:article) { create(:article, user: author) }
  let(:invitee) { create(:user) }

  def build_invitation(user: invitee, for_article: article)
    described_class.new(article: for_article, user: user)
  end

  describe "validations" do
    subject { create(:co_author_invitation, article: article, user: invitee) }

    it { is_expected.to belong_to(:article) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:article_id) }

    it "is valid for a follower of the author on a personal post" do
      invitee.follow(author)

      expect(build_invitation).to be_valid
    end

    it "is invalid when the invitee does not follow the author", :aggregate_failures do
      invitation = build_invitation

      expect(invitation).not_to be_valid
      expect(invitation.errors.full_messages.join).to include("@#{invitee.username} needs to follow you")
    end

    it "is invalid when the author follows the invitee but not the other way around" do
      author.follow(invitee)

      expect(build_invitation).not_to be_valid
    end

    it "is invalid when the author has blocked the invitee" do
      invitee.follow(author)
      create(:user_block, blocker: author, blocked: invitee, config: "default")

      expect(build_invitation).not_to be_valid
    end

    it "is invalid when the invitee has blocked the author" do
      invitee.follow(author)
      create(:user_block, blocker: invitee, blocked: author, config: "default")

      expect(build_invitation).not_to be_valid
    end

    it "is invalid when the invitee is suspended" do
      invitee.follow(author)
      invitee.add_role(:suspended)

      expect(build_invitation).not_to be_valid
    end

    it "is invalid when inviting the author" do
      expect(build_invitation(user: author)).not_to be_valid
    end

    it "is invalid on an organization post", :aggregate_failures do
      invitee.follow(author)
      org_article = create(:article, user: author, organization: create(:organization))
      invitation = build_invitation(for_article: org_article)

      expect(invitation).not_to be_valid
      expect(invitation.errors.full_messages).to include("Co-author invitations are only available on personal posts.")
    end

    it "only checks eligibility when the invitation is created" do
      invitation = create(:co_author_invitation, article: article, user: invitee)
      invitee.stop_following(author)

      expect(invitation.reload.update(status: :accepted)).to be(true)
    end
  end

  describe ".eligible_invitees_for" do
    it "returns the author's followers in good standing", :aggregate_failures do
      follower = create(:user)
      spammer = create(:user)
      stranger = create(:user)
      [follower, spammer].each { |user| user.follow(author) }
      spammer.add_role(:spam)

      eligible = described_class.eligible_invitees_for(author)

      expect(eligible).to include(follower)
      expect(eligible).not_to include(spammer, stranger, author)
    end
  end

  describe "notifications" do
    it "enqueues the invitation notification once created" do
      sidekiq_assert_enqueued_with(job: Notifications::CoAuthorInvitationWorker) do
        create(:co_author_invitation, article: article, user: invitee)
      end
    end

    it "deletes its notifications when destroyed" do
      invitation = create(:co_author_invitation, article: article, user: invitee)
      Notifications::CoAuthorInvitations::Send.call(invitation)

      expect { invitation.destroy }.to change(Notification, :count).by(-1)
    end
  end
end
