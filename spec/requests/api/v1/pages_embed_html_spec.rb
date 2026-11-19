require "rails_helper"

RSpec.describe "Api::V1::Pages for organization embed_html pages" do
  let(:v1_headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:org_admin) do
    create(:user).tap do |user|
      create(:organization_membership, user: user, organization: organization, type_of_user: "admin")
    end
  end
  let(:resource_admin) { create(:user, :single_resource_admin, resource: OrganizationPageManagement) }
  let(:page_admin) { create(:user, :single_resource_admin, resource: Page) }
  let(:unrelated_user) { create(:user) }
  let!(:showcase_page) do
    create(:page, organization: organization, slug: "#{organization.slug}/readme",
                  template: "full_within_layout", position: 0)
  end
  let!(:embed_page) { create_embed_page(organization, "widget") }
  let(:embed_params) do
    { organization_id: organization.id, template: "embed_html", title: "Contributors",
      slug: "contributors", body_html: "<div id='contributors'><script>window.x = 1;</script></div>" }
  end

  before do
    FeatureFlag.add(:org_readme)
    FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization])
  end

  after do
    FeatureFlag.disable(:org_readme, FeatureFlag::Actor[organization])
  end

  def create_embed_page(owner, suffix)
    create(:page, organization: owner, template: "embed_html", body_markdown: nil,
                  body_html: "<p>#{suffix}</p>", slug: "#{owner.slug}/embed/#{suffix}")
  end

  def headers_for(user)
    v1_headers.merge("api-key" => create(:api_secret, user: user).secret)
  end

  def list_embed_pages(org = organization)
    get api_pages_path(organization_id: org.id, kind: "embed"), headers: headers
  end

  def create_embed(params = embed_params)
    post api_pages_path, params: params.to_json, headers: headers
  end

  def update_embed(params, page = embed_page)
    put api_page_path(page.id), params: params.to_json, headers: headers
  end

  shared_examples "reads embed pages" do
    it "lists only the organization's embed pages, with body_html and no caching", :aggregate_failures do
      other_embed = create_embed_page(organization, "heatmap")
      create_embed_page(other_organization, "elsewhere")

      list_embed_pages

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.pluck("id")).to eq([embed_page.id, other_embed.id])
      expect(response.parsed_body.first).to include("template" => "embed_html", "body_html" => "<p>widget</p>")
      expect(response.headers["Cache-Control"]).to eq("private, no-store")
      expect(response.headers["Surrogate-Control"]).to eq("no-store")
    end

    it "keeps embed pages out of the default organization listing" do
      get api_pages_path(organization_id: organization.id), headers: headers

      expect(response.parsed_body.pluck("id")).to eq([showcase_page.id])
    end

    it "shows an embed page with body_html", :aggregate_failures do
      get api_page_path(embed_page.id), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("id" => embed_page.id, "body_html" => "<p>widget</p>")
      expect(response.headers["Cache-Control"]).to eq("private, no-store")
      expect(response.headers["Surrogate-Control"]).to eq("no-store")
    end
  end

  shared_examples "writes embed pages" do
    it "creates an embed page with a namespaced slug and only embed fields", :aggregate_failures do
      expect do
        create_embed(embed_params.merge(body_markdown: "# Ignored", body_css: "body {}", is_top_level_path: true,
                                        position: 5, show_in_navigation: false))
      end.to change(organization.pages.embed_html, :count).by(1)

      expect(response).to have_http_status(:ok)
      created = Page.find(response.parsed_body["id"])
      expect(created).to have_attributes(
        slug: "#{organization.slug}/embed/contributors",
        template: "embed_html",
        body_html: embed_params[:body_html],
        processed_html: embed_params[:body_html],
        body_markdown: nil,
        body_css: nil,
        is_top_level_path: false,
        position: 0,
        show_in_navigation: true,
        description: organization.summary.presence || organization.name,
      )
      expect(organization.ordered_pages).not_to include(created)
      expect(organization.main_page).to eq(showcase_page)
    end

    it "updates the body_html, title and slug of an embed page", :aggregate_failures do
      update_embed({ title: "Heatmap", body_html: "<p>fresh</p>", slug: "heatmap" })

      expect(response).to have_http_status(:ok)
      expect(embed_page.reload).to have_attributes(
        title: "Heatmap", body_html: "<p>fresh</p>", processed_html: "<p>fresh</p>",
        slug: "#{organization.slug}/embed/heatmap", template: "embed_html"
      )
    end

    it "sends Cache-Control: private, no-store and Surrogate-Control: no-store on embed write responses",
       :aggregate_failures do
      create_embed
      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to eq("private, no-store")
      expect(response.headers["Surrogate-Control"]).to eq("no-store")

      create_embed(embed_params.merge(slug: "other", body_html: ""))
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.headers["Cache-Control"]).to eq("private, no-store")
      expect(response.headers["Surrogate-Control"]).to eq("no-store")

      update_embed({ body_html: "<p>fresh</p>" })
      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to eq("private, no-store")
      expect(response.headers["Surrogate-Control"]).to eq("no-store")
    end

    it "serves API-written HTML only through the sandboxed embed endpoint", :aggregate_failures do
      create_embed
      created = Page.find(response.parsed_body["id"])

      get "/#{created.slug}", params: { mode: "embed" }, headers: { "Sec-Fetch-Dest" => "iframe" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<div id='contributors'>").or include('<div id="contributors">')
      expect(response.body).to include('data-forem-wrapper-script="1"')
      expect(response.headers["Content-Security-Policy"]).to include("sandbox")
      expect(response.headers["Content-Security-Policy"]).not_to include("allow-same-origin")

      expect { get "/page/#{created.slug}" }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "keeps the slug when the update omits it" do
      update_embed({ body_html: "<p>fresh</p>" })

      expect(embed_page.reload.slug).to eq("#{organization.slug}/embed/widget")
    end
  end

  shared_examples "hides embed pages" do |write_status:|
    it "refuses the embed listing" do
      list_embed_pages

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not show an embed page" do
      get api_page_path(embed_page.id), headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "does not create an embed page", :aggregate_failures do
      expect { create_embed }.not_to change(Page, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not update an embed page", :aggregate_failures do
      update_embed({ body_html: "<p>hijacked</p>" })

      expect(response).to have_http_status(write_status)
      expect(embed_page.reload.body_html).to eq("<p>widget</p>")
    end

    it "does not destroy an embed page", :aggregate_failures do
      delete api_page_path(embed_page.id), headers: headers

      expect(response).to have_http_status(write_status)
      expect(Page.exists?(embed_page.id)).to be(true)
    end
  end

  context "when authenticated as an organization admin" do
    let(:headers) { headers_for(org_admin) }

    it_behaves_like "reads embed pages"
    it_behaves_like "writes embed pages"

    it "destroys an embed page", :aggregate_failures do
      expect { delete api_page_path(embed_page.id), headers: headers }.to change(Page, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to eq("private, no-store")
      expect(response.headers["Surrogate-Control"]).to eq("no-store")
    end

    it "handles missing, non-existent, and malformed organization_id or slug params without crashing",
       :aggregate_failures do
      get api_pages_path(kind: "embed"), headers: headers
      expect(response).to have_http_status(:unauthorized)

      get api_pages_path(kind: "embed", organization_id: 999_999_999), headers: headers
      expect(response).to have_http_status(:unauthorized)

      get "/api/pages?kind=embed&organization_id[]=#{organization.id}&organization_id[]=#{other_organization.id}",
          headers: headers
      expect(response).to have_http_status(:unauthorized)

      create_embed(embed_params.merge(organization_id: [organization.id]))
      expect(response).to have_http_status(:unauthorized)

      create_embed(embed_params.merge(slug: ["array-slug"]))
      expect(response).to have_http_status(:unprocessable_entity)

      update_embed({ organization_id: [organization.id], body_html: "<p>bad</p>" })
      expect(response).to have_http_status(:unauthorized)

      update_embed({ organization_id: "#{organization.id}abc", body_html: "<p>bad</p>" })
      expect(response).to have_http_status(:unauthorized)

      patch api_page_path(embed_page.id), params: { body_html: "<p>patched</p>" }.to_json, headers: headers
      expect(response).to have_http_status(:ok)
      expect(embed_page.reload.body_html).to eq("<p>patched</p>")
    end

    it "accepts a full namespaced slug and a slug_suffix", :aggregate_failures do
      create_embed(embed_params.merge(slug: "#{organization.slug}/embed/full-slug"))
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["slug"]).to eq("#{organization.slug}/embed/full-slug")

      create_embed(embed_params.except(:slug).merge(slug_suffix: "Suffix Only!"))
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["slug"]).to eq("#{organization.slug}/embed/suffix-only")
    end

    it "rejects slugs outside the organization's embed namespace", :aggregate_failures do
      ["!!!", "", "#{other_organization.slug}/embed/widget", "#{organization.slug}/widget", "embed/widget",
       "#{organization.slug}/embed/a/b"].each do |slug|
        expect { create_embed(embed_params.merge(slug: slug)) }.not_to change(Page, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      update_embed({ slug: "#{other_organization.slug}/embed/widget" })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(embed_page.reload.slug).to eq("#{organization.slug}/embed/widget")
    end

    it "does not create a Markdown page inside the embed namespace" do
      expect do
        post api_pages_path, params: { organization_id: organization.id, title: "X", body_markdown: "X",
                                       slug: "#{organization.slug}/embed/x" }.to_json, headers: headers
      end.not_to change(Page, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a duplicate embed slug" do
      expect { create_embed(embed_params.merge(slug: "widget")) }.not_to change(Page, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not switch an embed page to a Markdown template", :aggregate_failures do
      update_embed({ template: "full_within_layout", body_markdown: "# Now Markdown" })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.headers["X-Error-Text"]).to include(I18n.t("models.page.embed_html_template_immutable"))
      expect(embed_page.reload.template).to eq("embed_html")
    end

    it "does not switch a Markdown page to embed_html", :aggregate_failures do
      put api_page_path(showcase_page.id), params: { template: "embed_html", body_html: "<p>x</p>" }.to_json,
                                           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.headers["X-Error-Text"]).to include(I18n.t("models.page.embed_html_template_immutable"))
      expect(showcase_page.reload.template).to eq("full_within_layout")
    end

    it "rejects body_html over the size limit on create and update", :aggregate_failures do
      oversized = "<p>#{'a' * Page::MAX_EMBED_HTML_BYTES}</p>"
      message = I18n.t("models.page.embed_html_too_large", max_kb: Page::MAX_EMBED_HTML_BYTES / 1.kilobyte)

      expect { create_embed(embed_params.merge(body_html: oversized)) }.not_to change(Page, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.headers["X-Error-Text"]).to include(message)

      update_embed({ body_html: oversized })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(embed_page.reload.body_html).to eq("<p>widget</p>")
    end

    it "rejects body_html beyond the DOM complexity limits" do
      create_embed(embed_params.merge(body_html: "#{'<div>' * 300}deep#{'</div>' * 300}"))

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.headers["X-Error-Text"]).to include(I18n.t("models.page.embed_html_too_complex"))
    end

    it "rejects an empty body_html" do
      expect { create_embed(embed_params.merge(body_html: "")) }.not_to change(Page, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "stores Liquid tags in body_html verbatim instead of rendering them" do
      liquid = "<p>{% github forem/forem %} {{ site.name }}</p>"
      create_embed(embed_params.merge(body_html: liquid))

      expect(Page.find(response.parsed_body["id"]).processed_html).to eq(liquid)
    end

    it "enforces the organization embed page cap", :aggregate_failures do
      stub_const("Page::MAX_ORGANIZATION_EMBED_PAGES", 1)

      expect { create_embed }.not_to change(Page, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.headers["X-Error-Text"])
        .to include(I18n.t("models.page.organization_embed_pages_limit_reached", max: 1))
    end

    it "logs embed writes in the admin API audit log", :aggregate_failures do
      Audit::Subscribe.listen :admin_api
      create_embed
      created_id = response.parsed_body["id"]
      expect(AuditLog.last.data).to eq("action" => "api_page_create", "page_id" => created_id)

      update_embed({ body_html: "<p>fresh</p>" })
      expect(AuditLog.last.data).to eq("action" => "api_page_update", "page_id" => embed_page.id)

      delete api_page_path(embed_page.id), headers: headers
      expect(AuditLog.last).to have_attributes(user_id: org_admin.id, slug: "api_page_destroy")
    ensure
      Audit::Subscribe.forget :admin_api
    end

    context "with another organization's embed page" do
      let(:foreign_embed) { create_embed_page(other_organization, "foreign") }

      before { FeatureFlag.enable(:org_readme, FeatureFlag::Actor[other_organization]) }
      after { FeatureFlag.disable(:org_readme, FeatureFlag::Actor[other_organization]) }

      it "cannot list, show, create, update or destroy it", :aggregate_failures do
        list_embed_pages(other_organization)
        expect(response).to have_http_status(:unauthorized)

        get api_page_path(foreign_embed.id), headers: headers
        expect(response).to have_http_status(:not_found)

        expect { create_embed(embed_params.merge(organization_id: other_organization.id)) }
          .not_to change(Page, :count)
        expect(response).to have_http_status(:unauthorized)

        update_embed({ body_html: "<p>hijacked</p>" }, foreign_embed)
        expect(response).to have_http_status(:not_found)

        delete api_page_path(foreign_embed.id), headers: headers
        expect(response).to have_http_status(:not_found)
        expect(foreign_embed.reload.body_html).to eq("<p>foreign</p>")
      end

      it "cannot move its own embed page to another organization", :aggregate_failures do
        update_embed({ organization_id: other_organization.id, body_html: "<p>moved</p>" })

        expect(response).to have_http_status(:unauthorized)
        expect(embed_page.reload).to have_attributes(organization_id: organization.id, body_html: "<p>widget</p>")
      end
    end

    context "when org_readme is disabled for the organization" do
      before { FeatureFlag.disable(:org_readme, FeatureFlag::Actor[organization]) }

      it_behaves_like "hides embed pages", write_status: :not_found
    end
  end

  context "when authenticated as the organization pages Resource Admin" do
    let(:headers) { headers_for(resource_admin) }

    it_behaves_like "reads embed pages"
    it_behaves_like "writes embed pages"

    it "cannot destroy an embed page", :aggregate_failures do
      delete api_page_path(embed_page.id), headers: headers

      expect(response).to have_http_status(:unauthorized)
      expect(Page.exists?(embed_page.id)).to be(true)
    end

    it "marks embed writes as made through the Resource Admin role", :aggregate_failures do
      Audit::Subscribe.listen :admin_api
      create_embed
      expect(AuditLog.last).to have_attributes(user_id: resource_admin.id, slug: "api_page_create")
      expect(AuditLog.last.data).to eq("action" => "api_page_create", "page_id" => response.parsed_body["id"],
                                       "via" => "org_pages_resource_admin", "organization_id" => organization.id)

      update_embed({ body_html: "<p>fresh</p>" })
      expect(AuditLog.last.data).to eq("action" => "api_page_update", "page_id" => embed_page.id,
                                       "via" => "org_pages_resource_admin", "organization_id" => organization.id)
    ensure
      Audit::Subscribe.forget :admin_api
    end

    it "does not switch an embed page to a Markdown template" do
      update_embed({ template: "full_within_layout" })

      expect(response).to have_http_status(:unprocessable_entity)
    end

    context "when org_readme is disabled for the organization" do
      before { FeatureFlag.disable(:org_readme, FeatureFlag::Actor[organization]) }

      it_behaves_like "hides embed pages", write_status: :not_found
    end
  end

  context "when authenticated as a site page admin" do
    let(:headers) { headers_for(page_admin) }

    it_behaves_like "reads embed pages"
    it_behaves_like "writes embed pages"

    it "destroys an embed page" do
      expect { delete api_page_path(embed_page.id), headers: headers }.to change(Page, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it "requires an organization_id to create an embed page" do
      expect { create_embed(embed_params.except(:organization_id)) }.not_to change(Page, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "validates organization_id on embed listings without crashing on non-scalar values", :aggregate_failures do
      get api_pages_path(kind: "embed"), headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.headers["Cache-Control"]).to eq("private, no-store")
      expect(response.headers["Surrogate-Control"]).to eq("no-store")

      get "/api/pages?kind=embed&organization_id[]=#{organization.id}&organization_id[]=#{other_organization.id}",
          headers: headers
      expect(response).to have_http_status(:unprocessable_entity)

      get api_pages_path(kind: "embed", organization_id: 999_999_999), headers: headers
      expect(response).to have_http_status(:not_found)
      expect(response.headers["Cache-Control"]).to eq("private, no-store")
      expect(response.headers["Surrogate-Control"]).to eq("no-store")
    end

    it "does not switch templates in either direction", :aggregate_failures do
      update_embed({ template: "contained" })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(embed_page.reload.template).to eq("embed_html")

      put api_page_path(showcase_page.id), params: { template: "embed_html" }.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(showcase_page.reload.template).to eq("full_within_layout")
    end

    it "still cannot reach a user-owned embed page" do
      user_embed = create(:page, user: unrelated_user)

      get api_page_path(user_embed.id), headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when authenticated as a non-admin organization member" do
    let(:org_member) do
      create(:user).tap do |user|
        create(:organization_membership, user: user, organization: organization, type_of_user: "member")
      end
    end
    let(:headers) { headers_for(org_member) }

    it_behaves_like "hides embed pages", write_status: :not_found
  end

  context "when authenticated as a suspended organization admin" do
    let(:headers) { headers_for(org_admin) }

    before { org_admin.add_role(:suspended) }

    it_behaves_like "hides embed pages", write_status: :unauthorized
  end

  context "when authenticated as an unrelated user" do
    let(:headers) { headers_for(unrelated_user) }

    it_behaves_like "hides embed pages", write_status: :not_found
  end

  context "when unauthenticated" do
    let(:headers) { v1_headers }

    it_behaves_like "hides embed pages", write_status: :unauthorized

    it "keeps embed pages out of public listings", :aggregate_failures do
      get api_pages_path(organization_id: organization.id), headers: headers
      expect(response.parsed_body.pluck("id")).to eq([showcase_page.id])

      get api_pages_path, headers: headers
      expect(response.parsed_body.pluck("id")).not_to include(embed_page.id)
    end
  end
end
