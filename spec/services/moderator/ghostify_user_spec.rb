require "rails_helper"

RSpec.describe Moderator::GhostifyUser do
  let(:action_user) { create(:user) }
  let(:target_user) { create(:user) }
  let(:ghost_user) { create(:user) }

  before do
    Settings::Community.ghost_user_id = ghost_user.id
  end

  it "moves articles and comments to the ghost account" do
    create_list(:article, 2, user: target_user)
    create_list(:comment, 2, user: target_user)

    expect(target_user.articles.count).to eq(2)
    expect(target_user.comments.count).to eq(2)
    expect(ghost_user.articles.count).to eq(0)
    expect(ghost_user.comments.count).to eq(0)

    described_class.call(target_user_id: target_user.id, action_user_id: action_user.id)

    expect(target_user.articles.count).to eq(0)
    expect(target_user.comments.count).to eq(0)
    expect(ghost_user.articles.count).to eq(2)
    expect(ghost_user.comments.count).to eq(2)
  end

  it "creates an audit log" do
    create(:article, user: target_user)
    create(:comment, user: target_user)

    Audit::Subscribe.listen :moderator

    expect {
      described_class.call(target_user_id: target_user.id, action_user_id: action_user.id)
    }.to change { AuditLog.count }.by(1)

    log = AuditLog.last
    expect(log.user_id).to eq(action_user.id)
    expect(log.data["action"]).to eq("ghostify_user")
    expect(log.data["target_user_id"]).to eq(target_user.id)
    expect(log.data["ghost_user_id"]).to eq(ghost_user.id)

    Audit::Subscribe.forget :moderator
  end
end
