require "rails_helper"

RSpec.describe Organizations::RecompilePagesWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "default", 1

  describe "#perform" do
    let(:organization) { create(:organization) }
    let!(:page) do
      create(:page, organization: organization, body_markdown: "# Title\n{% org_posts #{organization.slug} %}",
                    title: "Readme", description: "desc", slug: "#{organization.slug}/readme")
    end

    before do
      FeatureFlag.add(:org_readme)
    end

    context "when :org_readme feature is disabled" do
      before do
        FeatureFlag.disable(:org_readme, FeatureFlag::Actor[organization])
      end

      it "does not recompile the organization pages" do
        expect_any_instance_of(Page).not_to receive(:recompile!)
        described_class.new.perform(organization.id)
      end
    end

    context "when :org_readme feature is enabled" do
      before do
        FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization])
      end

      it "recompiles the organization pages" do
        expect_any_instance_of(Page).to receive(:recompile!).and_call_original
        described_class.new.perform(organization.id)
      end

      it "updates processed_html during recompilation" do
        # Setup initial content that renders without articles
        expect(page.processed_html).not_to include("An Amazing Article")

        # Create a published article
        create(:article, organization: organization, published: true, title: "An Amazing Article")

        described_class.new.perform(organization.id)
        expect(page.reload.processed_html).to include("An Amazing Article")
      end
    end
  end
end
