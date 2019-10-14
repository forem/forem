require "rails_helper"

RSpec.describe Users::ResaveArticlesJob, type: :job do
  include_examples "#enqueues_job", "users_resave_articles", [1, 2]

  describe "#perform_now" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }

    it "resaves articles" do
      old_updated_at = article.updated_at
      Timecop.freeze(Time.current) do
        described_class.perform_now(user.id)
        expect(article.reload.updated_at > old_updated_at).to be(true)
      end
    end
  end
end
