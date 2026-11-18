require "rails_helper"

RSpec.describe Organizations::SaveArticleWorker do
  describe "perform" do
    let(:worker) { subject }
    let(:organization) { create(:organization) }
    let!(:articles) { create_list(:article, 3, organization: organization) }

    describe "save articles with worker" do
      it "refreshes every article's cached organization on a slug change", :aggregate_failures do
        new_slug = "newSlug"
        organization.update!(slug: new_slug)

        expect(described_class.jobs.pluck("args")).to match_array(articles.map { |article| [article.id] })

        sidekiq_perform_enqueued_jobs(only: described_class)

        articles.each do |article|
          article.reload
          expect(article.created_at).not_to eq(article.updated_at)
          expect(article.cached_organization.slug).to eq(organization.slug)
        end
      end
    end
  end
end
