require "rails_helper"

RSpec.describe Organizations::SaveArticleWorker do
  describe "perform" do
    let(:worker) { subject }
    let(:organization) { create(:organization) }
    let!(:articles) { (1..3).map { |_a| create(:article, organization: organization) } } # rubocop:disable RSpec/LetSetup

    describe "save articles with worker" do
      it "on organization slug change" do
        new_slug = "newSlug"
        organization.update(slug: new_slug)

        sidekiq_perform_enqueued_jobs

        organization.articles.each do |article|
          # Articles were updated
          expect(article.created_at).not_to eq(article.updated_at)
        end
      end
    end
  end
end
