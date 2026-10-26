require "rails_helper"

RSpec.describe CoAuthorInvitations::Decline, type: :service do
  let(:author) { create(:user) }
  let(:article) { create(:article, user: author) }
  let(:invitee) { create(:user) }

  it "declines a pending invitation", :aggregate_failures do
    invitation = create(:co_author_invitation, article: article, user: invitee)
    Notifications::CoAuthorInvitations::Send.call(invitation)

    expect(described_class.call(invitation)).to be(true)

    expect(invitation.reload).to be_declined
    expect(Notification.find_by(user: invitee, notifiable: invitation).json_data.dig("co_author_invitation", "status"))
      .to eq("declined")
  end

  it "removes the credit when withdrawing after accepting", :aggregate_failures do
    invitation = create(:co_author_invitation, article: article, user: invitee)
    CoAuthorInvitations::Accept.call(invitation)

    described_class.call(invitation)

    expect(invitation.reload).to be_declined
    expect(article.reload.co_author_ids).to eq([])
    expect(Notification.exists?(user: author, notifiable: invitation, action: "Accepted")).to be(false)
  end

  it "does nothing for an invitation that was already declined" do
    invitation = create(:co_author_invitation, :declined, article: article, user: invitee)

    expect(described_class.call(invitation)).to be(false)
  end
end
