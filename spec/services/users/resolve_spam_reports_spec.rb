require "rails_helper"

RSpec.describe Users::ResolveSpamReports, type: :service do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:article2) { create(:article, user: user) }
  let(:article3) { create(:article, user: user2) }
  let(:comment) { create(:comment, user: user, commentable: article2) }
  let(:comment2) { create(:comment, user: user, commentable: article) }

  it "doesn't fail when user has no reports" do
    described_class.call(user)
  end

  def spam_report(url)
    create(:feedback_message, category: "spam", status: "Open", reported_url: url)
  end

  context "with reports" do
    let!(:rep) { spam_report(user.path) }
    let!(:rep2) { spam_report(URL.url(user.path)) }
    let!(:a_rep) { spam_report(article.path) }
    let!(:a_rep2) { spam_report(URL.url(article2.path)) }
    let!(:c_rep) { spam_report(comment.path) }
    let!(:c_rep2) { spam_report(URL.url(comment2.path)) }

    it "updates statused of the user's profile, article and comment reports", :aggregate_failures do
      described_class.call(user)
      expect(rep.reload.status).to eq("Resolved")
      expect(rep2.reload.status).to eq("Resolved")
      expect(a_rep.reload.status).to eq("Resolved")
      expect(a_rep2.reload.status).to eq("Resolved")
      expect(c_rep.reload.status).to eq("Resolved")
      expect(c_rep2.reload.status).to eq("Resolved")
    end

    it "doesn't update non-spam reports" do
      other_rep = create(:feedback_message, category: "other", status: "Open", reported_url: user.path)
      harassment_rep = create(:feedback_message, category: "harassment", status: "Open",
                                                 reported_url: URL.url(article.path))
      described_class.call(user)
      expect(other_rep.reload.status).to eq("Open")
      expect(harassment_rep.reload.status).to eq("Open")
    end

    it "doesn't update other users reports" do
      u2_rep = spam_report(URL.url(user2.path))
      a3_rep = spam_report(article3.path)
      described_class.call(user)
      expect(u2_rep.reload.status).to eq("Open")
      expect(a3_rep.reload.status).to eq("Open")
    end
  end
end
