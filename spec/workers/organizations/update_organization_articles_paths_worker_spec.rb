require "rails_helper"

RSpec.describe Organizations::UpdateOrganizationArticlesPathsWorker, type: :worker do
  describe "perform" do
    let(:worker) { subject }
    let(:organization) { create(:organization) }
    let(:articles) { (1..3).map { |_a| create(:article, organization: organization) } }

    describe "update article paths" do
      it "on organization slug change" do
        old_slug = organization.slug
        new_slug = "newSlug"
        organization.update(slug: new_slug)

        worker.perform(organization.id, old_slug, new_slug)

        articles.map do |article|
          expect(article.path).to eq("/#{organization.slug}/#{article.slug}")
        end
      end
    end
  end
end
