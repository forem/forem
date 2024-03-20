require "rails_helper"

RSpec.describe Users::ResolveSpamReports, type: :service do
  let(:user) { create(:user) }

  it "doesn't fail when user has no reports" do
    described_class.call(user)
  end

  it "updates statused of the user's profile reports" do
    rep = create(:feedback_message, category: "spam", status: "Open", reported_url: user.path)
    rep2 = create(:feedback_message, category: "spam", status: "Open", reported_url: URL.url(user.path))
    described_class.call(user)
    expect(rep.reload.status).to eq("Resolved")
    expect(rep2.reload.status).to eq("Resolved")
  end

  it "updates statused of the user's profile and article reports" do
  end

  it "updates statused of the user's profile, article and comment reports" do
  end

  it "doesn't update other users reports" do
  end
end
