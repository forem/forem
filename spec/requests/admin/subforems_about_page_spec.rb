require "rails_helper"

RSpec.describe "Admin Subforems About Page Generation", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:valid_scratch_params) do
    {
      subforem: {
        domain: "test-about.com",
        name: "Test About Community",
        brain_dump: "A community focused on testing and quality assurance",
        logo_url: "https://example.com/logo.png",
        bg_image_url: "https://example.com/background.jpg",
        discoverable: true,
        root: false
      }
    }
  end

  before do
    sign_in admin_user
    allow(Subforems::CreateFromScratchWorker).to receive(:perform_async)
  end

  describe "POST /admin/subforems with create_from_scratch parameters" do
    it "queues the worker with all parameters including name for about page generation" do
      expect do
        post admin_subforems_path, params: valid_scratch_params
      end.to change(Subforem, :count).by(1)

      subforem = Subforem.last
      expect(Subforems::CreateFromScratchWorker).to have_received(:perform_async).with(
        subforem.id,
        "A community focused on testing and quality assurance",
        "Test About Community",
        "https://example.com/logo.png",
        "https://example.com/background.jpg",
        'en',
      )

      expect(response).to redirect_to(admin_subforems_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("admin.subforems_controller.created_with_ai"))
    end
  end

  describe "About page generation in worker" do
    let(:subforem) { create(:subforem, domain: "test-about.com") }
    let(:brain_dump) { "A community focused on testing and quality assurance" }
    let(:name) { "Test About Community" }
    let(:mock_ai_response) do
      <<~RESPONSE
        # Welcome to Test About Community

        We're a community dedicated to testing and quality assurance practices.

        ## What We Do

        Our community focuses on:
        - Software testing methodologies
        - Quality assurance best practices
        - Test automation strategies
        - Bug reporting and tracking

        Join us in building better software through quality!
      RESPONSE
    end

    before do
      allow(Ai::Base).to receive(:new).and_return(double(call: mock_ai_response))
      allow(Settings::Community).to receive(:set_community_name).and_return(name)
      allow(Settings::UserExperience).to receive(:set_default_locale)
      allow(Images::GenerateSubforemImages).to receive(:call)
      allow(Ai::CommunityCopy).to receive(:new).and_return(double(write!: true))
      allow(Ai::ForemTags).to receive(:new).and_return(double(upsert!: true))
    end

    it "generates an about page when worker runs" do
      expect do
        Subforems::CreateFromScratchWorker.new.perform(
          subforem.id,
          brain_dump,
          name,
          "https://example.com/logo.png",
          "https://example.com/background.jpg",
          'en',
        )
      end.to change(Page, :count).by(1)

      page = Page.last
      expect(page.title).to eq("About #{name}")
      expect(page.description).to eq("Overview page for #{name}")
      expect(page.slug).to eq("about")
      expect(page.subforem_id).to eq(subforem.id)
      expect(page.is_top_level_path).to be true
      expect(page.template).to eq("contained")
      expect(page.body_markdown).to include("Welcome to Test About Community")
      expect(page.body_markdown).to include("testing and quality assurance")
    end
  end
end
