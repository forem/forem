require "rails_helper"

RSpec.describe CoAuthorInvitations::Accept, type: :service do
  let(:author) { create(:user) }
  let(:article) { create(:article, user: author) }
  let(:invitee) { create(:user) }
  let(:invitation) { create(:co_author_invitation, article: article, user: invitee) }

  before { Notifications::CoAuthorInvitations::Send.call(invitation) }

  it "credits the invitee as a co-author", :aggregate_failures do
    expect(described_class.call(invitation)).to be(true)

    expect(invitation.reload).to be_accepted
    expect(invitation.responded_at).to be_present
    expect(article.reload.co_author_ids).to eq([invitee.id])
  end

  it "keeps existing co-authors" do
    other = create(:co_author_invitation, :accepted, article: article)

    described_class.call(invitation)

    expect(article.reload.co_author_ids).to contain_exactly(other.user_id, invitee.id)
  end

  it "updates the invitee's notification and notifies the author", :aggregate_failures do
    described_class.call(invitation)

    invitee_notification = Notification.find_by(user: invitee, notifiable: invitation)
    expect(invitee_notification.json_data.dig("co_author_invitation", "status")).to eq("accepted")
    expect(invitee_notification).to be_read
    expect(Notification.exists?(user: author, notifiable: invitation, action: "Accepted")).to be(true)
  end

  it "does nothing for an invitation that was already answered", :aggregate_failures do
    invitation.update!(status: :declined)

    expect(described_class.call(invitation)).to be(false)
    expect(article.reload.co_author_ids).to eq([])
  end

  it "turns away a response once the post is under an organization", :aggregate_failures do
    article.update_columns(organization_id: create(:organization).id)

    expect(described_class.call(invitation)).to be(false)
    expect(invitation.reload).to be_pending
    expect(article.reload.co_author_ids).to eq([])
  end

  it "does nothing for an invitation that was withdrawn in the meantime" do
    stale_invitation = CoAuthorInvitation.find(invitation.id)
    invitation.destroy

    expect(described_class.call(stale_invitation)).to be(false)
  end

  it "rolls back when the article can't be saved", :aggregate_failures do
    # Listing the author as their own co-author makes the article invalid.
    article.update_columns(co_author_ids: [author.id])

    expect(described_class.call(invitation)).to be(false)
    expect(invitation.reload).to be_pending
    expect(article.reload.co_author_ids).to eq([author.id])
  end
end
