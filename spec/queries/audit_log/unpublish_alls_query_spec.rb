require "rails_helper"

RSpec.describe AuditLog::UnpublishAllsQuery, type: :query do
  let(:user) { create(:user) }
  let!(:article) { create(:article, user: user) }

  describe "::call" do
    context "when audit_log exists" do
      let!(:audit_log) do
        create(:audit_log, slug: "unpublish_all_articles",
                           data: { target_user_id: user.id, target_article_ids: [article.id] })
      end

      it "has articles and audit_log in the result" do
        res = described_class.call(user.id)
        expect(res.target_articles).to eq([article])
        expect(res.target_comments).to eq([])
        expect(res.audit_log).to eq(audit_log)
      end

      it "exists?" do
        res = described_class.call(user.id)
        expect(res.exists?).to be true
      end
    end

    it "doesn't exist when there is no related audit_log" do
      res = described_class.call(user.id)
      expect(res.exists?).to be false
    end
  end
end
