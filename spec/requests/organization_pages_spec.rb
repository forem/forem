require "rails_helper"

RSpec.describe "Organization Pages Controller Backend Protection" do
  let(:admin_user) { create(:user, :org_admin) }
  let(:organization) { admin_user.organizations.first }

  before do
    sign_in admin_user
  end

  after do
    FeatureFlag.disable(:org_readme, FeatureFlag::Actor[organization])
  end

  describe "GET /:slug/settings/pages" do
    context "when feature flag is disabled" do
      before { FeatureFlag.disable(:org_readme) }

      it "returns 404 Not Found" do
        expect do
          get organization_pages_path(organization.slug)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when feature flag is enabled" do
      before { FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization]) }

      it "returns 200 OK" do
        get organization_pages_path(organization.slug)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /:slug/settings/pages" do
    before { FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization]) }

    context "when creating the first page" do
      it "automatically creates the readme Showcase page" do
        expect {
          post organization_pages_path(organization.slug), params: {
            page: { title: "Welcome", body_markdown: "# Hello showcase" }
          }
        }.to change(Page, :count).by(1)

        page = organization.pages.last
        expect(page.slug).to eq("#{organization.slug}/readme")
        expect(page.title).to eq("Welcome")
      end

      it "defaults a blank first-page title to Showcase" do
        post organization_pages_path(organization.slug), params: {
          page: { title: " ", body_markdown: "# Hello showcase" }
        }

        expect(response).to redirect_to(organization_pages_path(organization.slug))
        expect(organization.main_page.title).to eq(I18n.t("views.organizations.showcase"))
      end

      it "returns a validation error when a lead form belongs to another organization" do
        other_form = create(:organization_lead_form)

        expect do
          post organization_pages_path(organization.slug), params: {
            page: {
              title: "Welcome",
              body_markdown: "{% org_lead_form #{other_form.id} %}"
            }
          }
        end.not_to change(Page, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include(I18n.t("liquid_tags.org_lead_form_tag.wrong_organization"))
      end
    end

    context "when creating subsequent pages" do
      before do
        # Create first page
        create(:page, organization: organization, slug: "#{organization.slug}/readme", template: "full_within_layout")
      end

      it "creates a custom page with a slug suffix" do
        expect {
          post organization_pages_path(organization.slug), params: {
            page: { title: "About Us", body_markdown: "# Custom about page", slug_suffix: "about" }
          }
        }.to change(Page, :count).by(1)

        page = organization.pages.last
        expect(page.slug).to eq("#{organization.slug}/about")
      end

      it "fails and returns 422 if the slug suffix is invalid" do
        expect {
          post organization_pages_path(organization.slug), params: {
            page: { title: "About Us", body_markdown: "# Custom about page", slug_suffix: "!!!" }
          }
        }.not_to change(Page, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /:slug/settings/pages/:id" do
    before { FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization]) }

    let!(:readme_page) { create(:page, organization: organization, slug: "#{organization.slug}/readme", template: "full_within_layout") }
    let!(:custom_page) { create(:page, organization: organization, slug: "#{organization.slug}/about", template: "full_within_layout") }

    it "updates details and prevents readme slug suffix change" do
      patch update_organization_page_path(organization.slug, readme_page), params: {
        page: { title: "Updated Showcase Title", slug_suffix: "something-else" }
      }
      expect(readme_page.reload.title).to eq("Updated Showcase Title")
      expect(readme_page.slug).to eq("#{organization.slug}/readme")
    end

    it "enqueues an edge cache bust for the page and its organization" do
      sidekiq_assert_enqueued_with(job: Pages::BustCacheWorker, args: [readme_page.slug, organization.id]) do
        patch update_organization_page_path(organization.slug, readme_page), params: {
          page: { title: "Updated Showcase Title" }
        }
      end
    end

    it "fails and returns 422 if the updated slug suffix is invalid" do
      patch update_organization_page_path(organization.slug, custom_page), params: {
        page: { title: "New Title", slug_suffix: "!!!" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(custom_page.reload.title).not_to eq("New Title")
    end
  end

  describe "DELETE /:slug/settings/pages/:id" do
    before { FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization]) }

    let!(:readme_page) { create(:page, organization: organization, slug: "#{organization.slug}/readme", template: "full_within_layout") }

    it "deletes the page" do
      expect {
        delete organization_page_path(organization.slug, readme_page)
      }.to change(Page, :count).by(-1)
    end
  end

  describe "PATCH /:slug/settings/pages/:id/reorder" do
    before { FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization]) }

    let!(:readme_page) do
      create(:page, organization: organization, slug: "#{organization.slug}/showcase",
                    template: "full_within_layout")
    end
    let!(:first_page) do
      create(:page, organization: organization, slug: "#{organization.slug}/first",
                    template: "full_within_layout")
    end
    let!(:second_page) do
      create(:page, organization: organization, slug: "#{organization.slug}/second",
                    template: "full_within_layout")
    end

    it "moves a custom page up while keeping Showcase first" do
      sidekiq_assert_enqueued_with(job: Pages::BustCacheWorker, args: [second_page.slug, organization.id]) do
        patch reorder_organization_page_path(organization.slug, second_page), params: { direction: "up" }
      end

      expect(response).to redirect_to(organization_pages_path(organization.slug))
      expect(organization.ordered_pages.ids).to eq([readme_page.id, second_page.id, first_page.id])
    end

    it "does not move the Showcase page" do
      patch reorder_organization_page_path(organization.slug, readme_page), params: { direction: "down" }

      expect(response).to redirect_to(organization_pages_path(organization.slug))
      expect(organization.ordered_pages.first).to eq(readme_page)
    end

    it "rejects an unsupported direction" do
      patch reorder_organization_page_path(organization.slug, second_page), params: { direction: "sideways" }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /:slug/settings/pages/preview" do
    before { FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization]) }

    it "renders the markdown preview" do
      post organization_pages_preview_path(organization.slug), params: { body_markdown: "**bold text**" }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["processed_html"]).to include("<strong>bold text</strong>")
    end
  end

  describe "Sandboxed Embedded HTML Pages management" do
    before { FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization]) }

    it "renders a separate section for embed HTML pages on GET /:slug/settings/pages", :aggregate_failures do
      create(
        :page,
        organization: organization,
        title: "Main Showcase",
        slug: "#{organization.slug}/readme",
        template: "full_within_layout",
        body_markdown: "# Showcase",
      )
      embed_page = create(
        :page,
        organization: organization,
        title: "Interactive Chart",
        slug: "#{organization.slug}/embed/chart",
        template: "embed_html",
        body_markdown: nil,
        body_html: "<div>Chart</div>",
      )

      get organization_pages_path(organization.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="section-markdown-pages"')
      expect(response.body).to include('id="section-embed-pages"')
      expect(response.body).to include("Interactive Chart")
      expect(response.body).to include("{% embed #{URL.url("/#{organization.slug}/embed/chart")} %}")
      expect(organization.ordered_pages).not_to include(embed_page)
      expect(organization.ordered_embed_pages).to eq([embed_page])
    end

    it "renders the sandboxed HTML editor on GET /:slug/settings/pages/new?kind=embed", :aggregate_failures do
      get new_organization_page_path(organization.slug, kind: "embed")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="org-embed-html-editor"')
      expect(response.body).to include("sandbox=\"#{OrganizationEmbedsController::SANDBOX_DIRECTIVE}\"")
      expect(response.body).not_to include("allow-same-origin")
    end

    it "creates an embed_html page without hijacking the Showcase /readme slot", :aggregate_failures do
      expect do
        post organization_pages_path(organization.slug), params: {
          page: {
            template: "embed_html",
            title: "Pricing Widget",
            slug_suffix: "pricing-widget",
            body_html: "<div id='pricing'><script>window.x = 1;</script></div>"
          }
        }
      end.to change(Page, :count).by(1)

      embed_page = organization.ordered_embed_pages.last
      expect(embed_page.slug).to eq("#{organization.slug}/embed/pricing-widget")
      expect(embed_page.template).to eq("embed_html")
      expect(embed_page.body_markdown).to be_nil
      expect(organization.main_page).to be_nil

      # Creating the first Markdown page afterwards still creates the Showcase /readme page
      post organization_pages_path(organization.slug), params: {
        page: { title: "Welcome Showcase", body_markdown: "# Hello" }
      }
      expect(organization.reload.main_page.slug).to eq("#{organization.slug}/readme")
    end

    it "updates and deletes an embed_html page and ignores reorder requests", :aggregate_failures do
      embed_page = create(
        :page,
        organization: organization,
        title: "Old Widget",
        slug: "#{organization.slug}/embed/old-widget",
        template: "embed_html",
        body_markdown: nil,
        body_html: "<p>Old</p>",
      )

      expected_args = ["#{organization.slug}/embed/new-widget", organization.id]
      sidekiq_assert_enqueued_with(job: Pages::BustCacheWorker, args: expected_args) do
        patch update_organization_page_path(organization.slug, embed_page), params: {
          page: {
            title: "New Widget",
            slug_suffix: "new-widget",
            body_html: "<p>Updated</p>"
          }
        }
      end

      expect(embed_page.reload.title).to eq("New Widget")
      expect(embed_page.slug).to eq("#{organization.slug}/embed/new-widget")
      expect(embed_page.body_html).to eq("<p>Updated</p>")

      patch reorder_organization_page_path(organization.slug, embed_page), params: { direction: "up" }
      expect(response).to redirect_to(organization_pages_path(organization.slug))

      expect do
        delete organization_page_path(organization.slug, embed_page)
      end.to change(Page, :count).by(-1)
    end
  end
end
