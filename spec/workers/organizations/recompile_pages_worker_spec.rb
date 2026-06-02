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

      it "does not raise an error and logs it if a page compilation fails" do
        bad_page = create(:page, organization: organization, body_markdown: "# Bad Page",
                                 title: "Bad Page", description: "desc", slug: "#{organization.slug}/bad")

        allow_any_instance_of(Page).to receive(:recompile!) do |instance|
          if instance.id == bad_page.id
            raise StandardError, "Something went wrong"
          else
            instance.save!
          end
        end

        allow(Rails.logger).to receive(:error)
        expect { described_class.new.perform(organization.id) }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(/failed to recompile page #{bad_page.id}/)
      end

      it "recompiles successfully when the page uses a legacy slug" do
        old_slug = organization.slug
        new_slug = "brand-new-slug"

        # Simulate slug change which stores old_slug
        organization.update!(slug: new_slug)
        expect(organization.reload.old_slug).to eq(old_slug)

        # Create page using the legacy slug in the tag
        legacy_page = create(:page, organization: organization, body_markdown: "{% org_posts #{old_slug} %}",
                                    title: "Legacy", description: "desc", slug: "#{new_slug}/legacy")

        # Create published article under new slug
        create(:article, organization: organization, published: true, title: "An Amazing Article")

        # Recompile should find the org by old_slug, render org posts tag, and include the article!
        described_class.new.perform(organization.id)
        expect(legacy_page.reload.processed_html).to include("An Amazing Article")
      end
    end
  end
end
