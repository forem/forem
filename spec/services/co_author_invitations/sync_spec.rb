require "rails_helper"

RSpec.describe CoAuthorInvitations::Sync, type: :service do
  let(:author) { create(:user) }
  let(:article) { create(:article, user: author) }
  let(:follower) { create(:user) }
  let(:other_follower) { create(:user) }

  before do
    [follower, other_follower].each { |user| user.follow(author) }
  end

  def sync(invitee_ids, for_article: article)
    described_class.new(for_article, invitee_ids).tap do |sync|
      sync.apply if sync.prepare && for_article.save
    end
  end

  it "creates a pending invitation for each new invitee" do
    sync([follower.id, other_follower.id.to_s])

    expect(article.co_author_invitations.pending.pluck(:user_id)).to contain_exactly(follower.id, other_follower.id)
  end

  it "works for an article that is saved in between #prepare and #apply" do
    new_article = build(:article, user: author)

    sync([follower.id], for_article: new_article)

    expect(new_article.co_author_invitations.pluck(:user_id)).to eq([follower.id])
  end

  it "leaves existing invitations alone" do
    invitation = create(:co_author_invitation, article: article, user: follower)

    expect { sync([follower.id]) }.not_to change { invitation.reload.updated_at }
  end

  it "withdraws a pending invitation dropped from the list" do
    invitation = create(:co_author_invitation, article: article, user: follower)

    sync([])

    expect(CoAuthorInvitation.exists?(invitation.id)).to be(false)
  end

  it "withdraws an accepted invitation and its co-author credit", :aggregate_failures do
    invitation = create(:co_author_invitation, :accepted, article: article, user: follower)
    article.reload

    sync([])

    expect(CoAuthorInvitation.exists?(invitation.id)).to be(false)
    expect(article.reload.co_author_ids).to eq([])
  end

  it "keeps declined invitations so they can't be re-sent" do
    invitation = create(:co_author_invitation, :declined, article: article, user: follower)

    sync([])

    expect(invitation.reload).to be_declined
  end

  it "can swap a co-author when the list is already at the limit" do
    invitees = create_list(:user, CoAuthorInvitation::MAX_PER_ARTICLE)
    invitees.each { |invitee| create(:co_author_invitation, article: article, user: invitee) }

    sync(invitees.drop(1).map(&:id) + [follower.id])

    expect(article.co_author_invitations.pluck(:user_id)).to contain_exactly(*invitees.drop(1).map(&:id), follower.id)
  end

  context "when the invitee responds between #prepare and #apply" do
    let!(:invitation) { create(:co_author_invitation, article: article, user: follower) }

    def withdraw_while
      result = described_class.new(article, [])
      result.prepare
      yield CoAuthorInvitation.find(invitation.id)
      article.save
      result.apply
    end

    it "still removes the credit of someone who just accepted", :aggregate_failures do
      withdraw_while { |fresh_invitation| CoAuthorInvitations::Accept.call(fresh_invitation) }

      expect(CoAuthorInvitation.exists?(invitation.id)).to be(false)
      expect(article.reload.co_author_ids).to eq([])
    end

    it "keeps the invitation of someone who just declined" do
      withdraw_while { |fresh_invitation| CoAuthorInvitations::Decline.call(fresh_invitation) }

      expect(invitation.reload).to be_declined
    end
  end

  describe "#prepare" do
    it "rejects users who don't follow the author", :aggregate_failures do
      stranger = create(:user)
      result = described_class.new(article, [stranger.id])

      expect(result.prepare).to be(false)
      expect(result.errors).to include(a_string_including("@#{stranger.username} needs to follow you"))
    end

    it "rejects re-inviting someone who declined", :aggregate_failures do
      create(:co_author_invitation, :declined, article: article, user: follower)
      result = described_class.new(article, [follower.id])

      expect(result.prepare).to be(false)
      expect(result.errors).to include("@#{follower.username} declined your invitation to co-author this post.")
    end

    it "rejects more than the maximum number of invitees" do
      invitees = create_list(:user, CoAuthorInvitation::MAX_PER_ARTICLE + 1)
      invitees.each { |invitee| invitee.follow(author) }
      result = described_class.new(article, invitees.map(&:id))

      expect(result.prepare).to be(false)
    end

    it "rejects new invitations on an organization post" do
      article.organization = create(:organization)
      result = described_class.new(article, [follower.id])

      expect(result.prepare).to be(false)
    end

    it "does not touch the database when the list is invalid", :aggregate_failures do
      invitation = create(:co_author_invitation, :accepted, article: article, user: follower)
      article.reload
      result = described_class.new(article, [create(:user).id])

      expect(result.prepare).to be(false)
      expect(article.co_author_ids).to eq([follower.id])
      expect(CoAuthorInvitation.exists?(invitation.id)).to be(true)
    end
  end
end
