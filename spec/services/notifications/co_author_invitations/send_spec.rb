require "rails_helper"

RSpec.describe Notifications::CoAuthorInvitations::Send, type: :service do
  let(:author) { create(:user) }
  let(:invitee) { create(:user) }
  let(:article) { create(:article, user: author, published: false) }
  let(:invitation) { create(:co_author_invitation, article: article, user: invitee) }

  it "notifies the invitee", :aggregate_failures do
    notification = described_class.call(invitation)

    expect(notification.user_id).to eq(invitee.id)
    expect(notification.notifiable).to eq(invitation)
    expect(notification.action).to eq("Invited")
  end

  it "includes the inviting author and a link the invitee can open on a draft", :aggregate_failures do
    json_data = described_class.call(invitation).json_data

    expect(json_data.dig("user", "id")).to eq(author.id)
    expect(json_data.dig("article", "path")).to eq(article.current_state_path)
    expect(json_data.dig("article", "path")).to include("preview=")
    expect(json_data.dig("co_author_invitation", "status")).to eq("pending")
  end

  it "does not notify twice" do
    described_class.call(invitation)

    expect { described_class.call(invitation) }.not_to change(Notification, :count)
  end
end
