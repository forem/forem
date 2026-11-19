require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "api/v1/pages" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let!(:existing_page) { create(:page) }
  let(:user) { api_secret.user }

  before do
    user.add_role(:admin)
  end

  path "/api/pages" do
    describe "get to view all pages" do
      get("show details for all pages") do
        security []
        tags "pages"
        description(<<-DESCRIBE.strip)
        Retrieve details for all Page objects in the system.

        ### Pages Overview:
        - Pages are custom static or dynamic views hosted on the Forem instance.
        - Publicly visible unless restricted; pages belonging to unpublished events require page or event admin authentication.
        - Helpful for building custom menus, rendering site policies, or embedding custom forms.
        - Embed-only HTML pages (`template: "embed_html"`) are never included in this listing.

        ### Organization embed pages:
        Pass `kind=embed` with `organization_id` to list that organization's embed-only HTML pages instead, ordered by creation and including `body_html`, so a client can compare content before updating. This requires authentication as a site page admin, or, when the organization pages feature is enabled for the organization, as one of its admins or a holder of the `Resource Admin: OrganizationPageManagement` role. Other callers receive `401`, and responses are sent with `Cache-Control: private, no-store`.
        DESCRIBE

        produces "application/json"

        parameter name: :organization_id, in: :query, required: false,
                  description: "Filter pages belonging to a specific organization ID, ordered by position.",
                  schema: { type: :integer, format: :int64 }
        parameter name: :event_id, in: :query, required: false,
                  description: "Filter pages belonging to a specific event ID, ordered by position.",
                  schema: { type: :integer, format: :int64 }
        parameter name: :kind, in: :query, required: false,
                  description: "Set to `embed` with `organization_id` to list the organization's embed-only HTML pages. Requires authorization.",
                  schema: { type: :string, enum: ["embed"] }

        response(200, "successful") do
          schema type: :array,
                 items: { "$ref": "#/components/schemas/Page" }
          add_examples

          run_test!
        end

        response "401", "unauthorized embed page listing" do
          let(:organization_id) { create(:organization).id }
          let(:kind) { "embed" }
          add_examples

          run_test!
        end
      end
    end

    describe "create a new page" do
      post("pages") do
        tags "pages"
        description(<<-DESCRIBE.strip)
        Create a new custom page. Requires site administrative privileges, or organization admin privileges for the specified `organization_id` (when the organization pages feature is enabled). Holders of the `Resource Admin: OrganizationPageManagement` role can also create pages of any organization with the organization pages feature enabled, without being a member; those writes add `via` and `organization_id` to the audit log entry.  Successful writes log `api_page_create` with the actor and target ids in the admin API audit log.

        ### Body Parameter Guidelines:
        - **title**: Heading displayed at the top of the page.
        - **slug**: URL path identifier. Must be unique and URL-safe. For organization pages, scoped under `{org_slug}/{suffix}` (with the first page defaulting to `{org_slug}/readme`). For event pages, scoped under `events/{event_name_slug}/{event_variation_slug}/{suffix}` (with `.../readme` acting as the optional Showcase/README landing view).
        - **body_markdown**: Content written in Markdown format.
        - **body_json**: Optional JSON payload for API-consumed/structured data pages.
        - **is_top_level_path**: Set to `true` to serve the page directly at the root (e.g. `/{slug}`) instead of under the default namespace `/page/{slug}`. Use with caution to avoid namespace collisions with core Forem paths.
        - **template**: Layout styling options (`contained` or custom layouts). Organization Markdown pages always use `full_within_layout`; send `embed_html` to create an organization embed page (see below).
        - **organization_id**: Optional ID of the organization this page belongs to.
        - **event_id**: Optional ID of the event this page belongs to.
        - **position**: Optional display order position for organization or event pages.
        - **show_in_navigation**: Whether the page appears in organization or event tabs. Defaults to true. Only non-Showcase organization or event pages can set false. Hidden pages remain public at their URL and through the API.

        ### Organization embed pages:
        Send `template: "embed_html"` with `organization_id` to create an embed-only HTML page, served only inside sandboxed iframes through `{% embed %}`. The same callers who manage the organization's pages can create one, and site page admins must supply `organization_id` too.
        - Only `title`, `description`, `body_html` and `slug` (or `slug_suffix`) are used. The slug is always `{org_slug}/embed/{suffix}`, and either the suffix or the full slug is accepted.
        - `body_html` is stored as is and never rendered as Markdown or Liquid. It must be at most #{Page::MAX_EMBED_HTML_BYTES / 1.kilobyte} KB and stay within the HTML nesting depth and element count limits.
        - An organization can have at most #{Page::MAX_ORGANIZATION_EMBED_PAGES} embed pages.
        - The template is fixed at creation: an embed page can never become a Markdown page, and a Markdown page can never become an embed page.
        DESCRIBE

        produces "application/json"
        consumes "application/json"

        parameter name: :page, in: :body,
                  description: "Page parameters.",
                  schema: {
                    type: :object,
                    properties: {
                      title: { type: :string, description: "Title of the page" },
                      slug: { type: :string, description: "Used to link to this page in URLs, must be unique and URL-safe" },
                      description: { type: :string, description: "For internal use, helps similar pages from one another" },
                      body_markdown: { type: :string, description: "The text (in markdown) of the page (required unless the template is embed_html)" },
                      body_html: { type: :string, description: "For embed_html organization pages, the HTML document (required for them)" },
                      slug_suffix: { type: :string, description: "For organization pages, the part of the slug after the organization prefix" },
                      body_json: { type: :string, description: "For JSON pages, the JSON body" },
                      is_top_level_path: { type: :boolean,
                                           description: "If true, the page is available at '/{slug}' instead of '/page/{slug}', use with caution" },
                      organization_id: { type: :integer, format: :int64,
                                         description: "The ID of the organization the page belongs to" },
                      event_id: { type: :integer, format: :int64,
                                  description: "The ID of the event the page belongs to" },
                      position: { type: :integer, format: :int32,
                                  description: "Display order position for organization pages" },
                      show_in_navigation: { type: :boolean, default: true,
                                            description: "Whether the page appears in organization tabs. Defaults to true. Only non-Showcase organization pages can set false. Hidden pages remain public at their URL and through the API." },
                      template: {
                        type: :string, enum: Page::TEMPLATE_OPTIONS, default: "contained",
                        description: "Controls what kind of layout the page is rendered in"
                      }
                    }
                  }
        let(:page) do
          {
            title: "Example Page",
            slug: "example1",
            body_markdown: "# Hi, this is a New Page\nYep, it's an a new page",
            description: "a new page",
            template: template
          }
        end
        let(:template) { "contained" }

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end

        response "422", "unprocessable" do
          let(:"api-key") { api_secret.secret }
          let(:template) { "moon" }
          add_examples

          run_test!
        end
      end
    end
  end

  path "/api/pages/{id}" do
    describe "get to view a page" do
      get("show details for a page") do
        security []
        tags "pages"
        description(<<-DESCRIBE.strip)
        Retrieve details for a single Page object specified by ID. Embed-only HTML pages (`template: "embed_html"`) return `404` unless the caller is authenticated and may manage the organization's pages (see `GET /api/pages` with `kind=embed`).
        DESCRIBE

        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The unique ID of the page.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 1

        let(:id) { existing_page.id }

        response(200, "successful") do
          schema "$ref": "#/components/schemas/Page"
          add_examples

          run_test!
        end
      end
    end

    describe "put to update a page" do
      put("update details for a page") do
        tags "pages"
        description(<<-DESCRIBE.strip)
        Update an existing page's details by ID. `show_in_navigation` controls organization tabs only. Hidden pages remain public at their URL and through the API. Only non-Showcase organization pages can set it to false. Requires site administrative privileges, or organization admin privileges for pages belonging to an organization. Holders of the `Resource Admin: OrganizationPageManagement` role can also update pages of any organization with the organization pages feature enabled, without being a member; those writes add `via` and `organization_id` to the audit log entry. For embed-only HTML pages, only `title`, `description`, `body_html` and `slug` (or `slug_suffix`) are used, the slug stays under `{org_slug}/embed/`, and changing `template` returns `422`; callers who cannot manage the organization's pages receive `404`.  Successful writes log `api_page_update` with the actor and target ids in the admin API audit log.
        DESCRIBE

        produces "application/json"
        consumes "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The ID of the page to update.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 1
        parameter name: :page,
                  in: :body,
                  description: "Representation of Page to be updated",
                  schema: { "$ref": "#/components/schemas/Page" }

        let(:id) { existing_page.id }

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          let(:page) { attributes_for(:page, title: "New Title") }
          schema "$ref": "#/components/schemas/Page"
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          let(:page) { attributes_for(:page, title: "Doesn't Matter") }
          add_examples

          run_test!
        end

        response "422", "unprocessable" do
          let(:"api-key") { api_secret.secret }
          let(:page) { attributes_for(:page, template: "moon") }
          add_examples

          run_test!
        end
      end
    end

    describe "delete to destroy a page" do
      delete("remove a page") do
        tags "pages"
        description(<<-DESCRIBE.strip)
        Delete a custom page from the system by ID, including organization embed-only HTML pages. Requires site administrative privileges, or organization admin privileges for pages belonging to an organization. The `Resource Admin: OrganizationPageManagement` role cannot delete pages.  Successful writes log `api_page_destroy` with the actor and target ids in the admin API audit log.
        DESCRIBE

        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The ID of the page to delete.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 1

        let(:id) { existing_page.id }

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          schema "$ref": "#/components/schemas/Page"
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end

        response "422", "unprocessable" do
          let(:"api-key") { api_secret.secret }

          before do
            fake_page = instance_double(Page, destroy: false)
            allow(Page).to receive(:find).and_return(fake_page)
            allow(fake_page).to receive(:errors).and_return(instance_double(ActiveModel::Errors, full_messages: ["error"]))
          end

          add_examples

          run_test!
        end
      end
    end
  end

  path "/api/pages/preview" do
    describe "post to preview a page" do
      post("preview a page") do
        tags "pages"
        description(<<-DESCRIBE.strip)
        Render a page's Markdown (including organization Liquid tags when `organization_id` is supplied) into HTML without saving it. Requires site administrative privileges, or, for the supplied `organization_id` when the organization pages feature is enabled, organization admin privileges or the `Resource Admin: OrganizationPageManagement` role.
        DESCRIBE
        operationId "previewPage"
        produces "application/json"
        consumes "application/json"

        parameter name: :page, in: :body,
                  description: "Page content to preview.",
                  schema: {
                    type: :object,
                    properties: {
                      body_markdown: { type: :string, description: "The text (in markdown) of the page" },
                      body_html: { type: :string, description: "Raw HTML for site admin pages when body_markdown is omitted", nullable: true },
                      organization_id: { type: :integer, format: :int64, nullable: true,
                                         description: "The ID of the organization the page belongs to, if previewing an organization page" }
                    }
                  }

        let(:page) do
          {
            body_markdown: "# Hi, this is a Page Preview"
          }
        end

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          schema type: :object,
                 properties: {
                   processed_html: { type: :string }
                 }
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end

        response "422", "unprocessable" do
          let(:"api-key") { api_secret.secret }
          let(:page) { { body_markdown: "{% link invalid_link_that_does_not_exist %}" } }
          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable Layout/LineLength
# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
