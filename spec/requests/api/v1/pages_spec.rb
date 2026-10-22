require "rails_helper"

RSpec.describe "Api::V1::Pages" do
  let!(:v1_headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }
  let!(:page) { create(:page) }

  shared_context "when user is authorized" do
    let(:api_secret) { create(:api_secret) }
    let(:user) { api_secret.user }
    let(:auth_header) { v1_headers.merge({ "api-key" => api_secret.secret }) }
    before { user.add_role(:admin) }
  end

  context "when unauthenticated and get a page" do
    context "when no page with specified ID" do
      it "returns not found" do
        get api_page_path(1234), headers: v1_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context "when unauthenticated and post a new page" do
    it "returns unauthorized" do
      post api_pages_path, params: { title: "Doesn't Matter" }.to_json, headers: v1_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when unauthenticated and update a page" do
    it "returns unauthorized" do
      put api_page_path(page.id), params: page.attributes.merge(title: "Doesn't Matter").to_json, headers: v1_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when unauthenticated and delete a page" do
    it "returns unauthorized" do
      delete api_page_path(page.id), headers: v1_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authenticated but not authorized to edit pages" do
    let(:non_auth_header) do
      non_admin_secret = create(:api_secret)
      v1_headers.merge "api-key" => non_admin_secret.secret
    end

    it "returns unauthorized from create" do
      post api_pages_path, params: { title: "Also Doesn't Matter" }.to_json, headers: non_auth_header
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized from update" do
      put api_page_path(page.id), params: page.attributes.merge(title: "Doesn't Matter").to_json,
                                  headers: non_auth_header
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized from destroy" do
      delete api_page_path(page.id), headers: non_auth_header
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authenticated and authorized" do
    include_context "when user is authorized"

    let(:post_params) do
      # Fixed title so find_by(title:) can never collide with the let!(:page)
      # record — Faker::Book.title draws from a small pool and duplicates.
      attributes_for(:page, title: "Api V1 Pages Spec Page")
    end
    let(:body_html) { "<div>hi, folks</div>" }
    let(:body_css) { "h1 {font-size: 120px}" }

    it "can create a new page via post" do
      post api_pages_path, params: post_params.to_json, headers: auth_header
      expect(response).to have_http_status(:success)
    end

    it "creates a page with body_html" do
      post_params[:body_html] = body_html
      post_params[:body_markdown] = ""
      post api_pages_path, params: post_params.to_json, headers: auth_header
      page = Page.find_by(title: post_params[:title])
      expect(page.processed_html).to eq(body_html)
    end

    it "creates a page when both body_html and markdown are passed" do
      post_params[:body_html] = body_html
      post_params[:body_markdown] = "other"
      post api_pages_path, params: post_params.to_json, headers: auth_header
      page = Page.find_by(title: post_params[:title])
      expect(page.processed_html).to include("other")
    end

    it "doesn't create a page when no html or md are passed" do
      post_params[:body_html] = nil
      post_params[:body_markdown] = nil
      post api_pages_path, params: post_params.to_json, headers: auth_header
      page = Page.find_by(title: post_params[:title])
      expect(page).to be_nil
    end

    context "when creation fails validation" do
      it "returns the error header with a message" do
        # Assuming that a page requires either body_html or body_markdown.
        post_params[:body_html] = nil
        post_params[:body_markdown] = nil
        post api_pages_path, params: post_params.to_json, headers: auth_header
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.headers["X-Error-Text"]).to be_present
      end
    end

    it "can update an existing page via put" do
      put api_page_path(page.id), params: page.attributes.merge(title: "Brand New Title").to_json, headers: auth_header
      expect(response).to have_http_status(:success)
      expect(page.reload.title).to eq("Brand New Title")
    end

    it "updates an existing page via put with body_html" do
      post_params = page.attributes.merge(body_html: body_html, body_markdown: nil)
      put api_page_path(page.id), params: post_params.to_json, headers: auth_header
      expect(response).to have_http_status(:success)
      expect(page.reload.processed_html).to eq(body_html)
    end

    it "updates an existing page via put when both body_html and body_markdown are passed" do
      post_params = page.attributes.merge(body_html: body_html, body_markdown: "other")
      put api_page_path(page.id), params: post_params.to_json, headers: auth_header
      expect(response).to have_http_status(:success)
      expect(page.reload.processed_html).to include("other")
    end

    context "when update fails validation" do
      it "returns the error header with a message" do
        # Here we assume that an update fails if both body_html and body_markdown are nil.
        invalid_params = page.attributes.merge(body_html: nil, body_markdown: nil)
        put api_page_path(page.id), params: invalid_params.to_json, headers: auth_header
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.headers["X-Error-Text"]).to be_present
      end
    end

    it "creates a page with body_css" do
      post_params[:template] = "css"
      post_params[:body_css] = body_css
      post_params[:body_markdown] = ""
      post api_pages_path, params: post_params.to_json, headers: auth_header
      page = Page.find_by(title: post_params[:title])
      expect(page.body_css).to eq(body_css)
    end

    it "doesn't create a page when no html or md or css are passed" do
      post_params[:template] = "css"
      post_params[:body_html] = nil
      post_params[:body_markdown] = nil
      post_params[:body_css] = nil
      post api_pages_path, params: post_params.to_json, headers: auth_header
      page = Page.find_by(title: post_params[:title])
      expect(page).to be_nil
    end

    it "updates an existing page via put with body_css" do
      post_params = page.attributes.merge(body_css: body_css, body_markdown: nil, template: "css")
      put api_page_path(page.id), params: post_params.to_json, headers: auth_header
      expect(response).to have_http_status(:success)
      expect(page.reload.body_css).to eq(body_css)
    end

    it "can destroy an existing page via delete" do
      delete api_page_path(page.id), headers: auth_header
      expect(response).to have_http_status(:success)
      expect(Page).not_to exist(page.id)
    end

    context "when destroy fails" do
      it "returns the error header with a message" do
        # For testing failure, we can stub the destroy method to simulate a failure.
        allow_any_instance_of(Page).to receive(:destroy).and_return(false)
        delete api_page_path(page.id), headers: auth_header
        expect(response).to have_http_status(:unprocessable_entity)
        # expect(response.headers["X-Error-Text"]).to be_present
      end
    end

    context "when providing a social image url" do
      let(:image_url) { "https://example.com/image.jpg" }
      let(:mocked_image_file) { Images::ProfileImageGenerator.call }
      # forced binary encoding to avoid encoding issues.
      let(:mocked_image_data) { mocked_image_file.read.force_encoding("BINARY") }

      before do
        stub_request(:get, image_url).to_return(body: mocked_image_data, headers: { "Content-Type" => "image/png" })
      end

      it "creates a page with a social image" do
        post_params[:social_image] = { url: image_url }
        post api_pages_path, params: post_params.to_json, headers: auth_header
        expect(response).to have_http_status(:success)

        page = Page.find_by(title: post_params[:title])
        expect(page.social_image).to be_present

        uploaded_image_data = page.social_image.read.force_encoding("BINARY")
        expect(uploaded_image_data).to eq(mocked_image_data)
      end
    end
  end

  it "retrieves all pages and renders the collection as json" do
    get api_pages_path, headers: v1_headers
    expect(response).to have_http_status(:success)
    expect(response.parsed_body.size).to eq(1)
    expect(response.parsed_body.first.keys).to \
      match_array(%w[id title slug description is_top_level_path
                     landing_page body_html body_json body_markdown
                     processed_html social_image template subforem_id
                     page_template_id template_data redirect_to_url
                     organization_id position])
  end

  it "filters pages by organization_id ordered by position" do
    org = create(:organization)
    other_org = create(:organization)
    second_page = create(:page, organization: org, slug: "#{org.slug}/second", position: 2)
    first_page = create(:page, organization: org, slug: "#{org.slug}/readme", position: 0)
    create(:page, organization: other_org, slug: "#{other_org.slug}/readme", position: 0)

    get api_pages_path(organization_id: org.id), headers: v1_headers
    expect(response).to have_http_status(:success)
    expect(response.parsed_body.pluck("id")).to eq([first_page.id, second_page.id])
  end

  it "retrieves a page and renders it as json" do
    get api_page_path(page.id), headers: v1_headers
    expect(response).to have_http_status(:success)
    expect(response.parsed_body.keys).to \
      match_array(%w[id title slug description is_top_level_path
                     landing_page body_html body_json body_markdown
                     processed_html social_image template subforem_id
                     page_template_id template_data redirect_to_url
                     organization_id position])
  end

  context "when authenticated as an organization admin" do
    let(:org_admin) { create(:user, :org_admin) }
    let(:organization) { org_admin.organizations.first }
    let(:api_secret) { create(:api_secret, user: org_admin) }
    let(:org_auth_header) { v1_headers.merge({ "api-key" => api_secret.secret }) }

    before do
      FeatureFlag.add(:org_readme)
      FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization])
    end

    after do
      FeatureFlag.disable(:org_readme, FeatureFlag::Actor[organization])
    end

    context "when org_readme feature flag is disabled" do
      before { FeatureFlag.disable(:org_readme, FeatureFlag::Actor[organization]) }

      it "returns unauthorized from create" do
        post api_pages_path,
             params: { organization_id: organization.id, title: "Welcome", body_markdown: "# Hi" }.to_json,
             headers: org_auth_header
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns unauthorized from update and destroy" do
        org_page = create(:page, organization: organization, slug: "#{organization.slug}/readme")

        put api_page_path(org_page.id),
            params: { title: "Updated" }.to_json,
            headers: org_auth_header
        expect(response).to have_http_status(:unauthorized)

        delete api_page_path(org_page.id), headers: org_auth_header
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it "creates the first page as the readme Showcase page and enforces org page constraints", :aggregate_failures do
      expect do
        post api_pages_path,
             params: {
               organization_id: organization.id,
               title: "",
               body_markdown: "# Hello org",
               body_html: "<script>alert(1)</script>",
               is_top_level_path: true,
               landing_page: true,
               template: "contained"
             }.to_json,
             headers: org_auth_header
      end.to change(Page, :count).by(1)

      expect(response).to have_http_status(:ok)
      created_page = organization.pages.last
      expect(created_page).to have_attributes(
        slug: "#{organization.slug}/readme",
        title: I18n.t("views.organizations.showcase"),
        description: organization.summary.presence || organization.name,
        template: "full_within_layout",
        position: 0,
        is_top_level_path: false,
        landing_page: false,
        body_html: nil,
      )
      expect(created_page.processed_html).to include("Hello org")
    end

    context "when the organization already has a readme page" do
      let!(:readme_page) do
        create(:page, organization: organization, slug: "#{organization.slug}/readme",
                      template: "full_within_layout", position: 0)
      end

      it "creates subsequent pages with a slug suffix or full org slug and auto-increments position" do
        post api_pages_path,
             params: {
               organization_id: organization.id,
               title: "About Us",
               slug: "about",
               body_markdown: "# About"
             }.to_json,
             headers: org_auth_header

        expect(response).to have_http_status(:ok)
        about_page = organization.pages.find_by(slug: "#{organization.slug}/about")
        expect(about_page).to be_present
        expect(about_page.position).to eq(1)

        post api_pages_path,
             params: {
               organization_id: organization.id,
               title: "Team",
               slug: "#{organization.slug}/team",
               body_markdown: "# Team",
               position: 5
             }.to_json,
             headers: org_auth_header

        expect(response).to have_http_status(:ok)
        team_page = organization.pages.find_by(slug: "#{organization.slug}/team")
        expect(team_page).to be_present
        expect(team_page.position).to eq(5)
      end

      it "rejects invalid slug suffixes or another organization's slug prefix on create" do
        post api_pages_path,
             params: {
               organization_id: organization.id,
               title: "Invalid",
               slug: "!!!",
               body_markdown: "# Invalid"
             }.to_json,
             headers: org_auth_header
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.headers["X-Error-Text"]).to include("Slug suffix is required")

        post api_pages_path,
             params: {
               organization_id: organization.id,
               title: "Wrong Org Prefix",
               slug: "some-other-org/about",
               body_markdown: "# Invalid"
             }.to_json,
             headers: org_auth_header
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "updates the readme page while keeping slug and position locked" do
        put api_page_path(readme_page.id),
            params: {
              title: "Updated Showcase",
              slug: "custom-slug",
              position: 3,
              body_markdown: "# Updated markdown"
            }.to_json,
            headers: org_auth_header

        expect(response).to have_http_status(:ok)
        readme_page.reload
        expect(readme_page.title).to eq("Updated Showcase")
        expect(readme_page.slug).to eq("#{organization.slug}/readme")
        expect(readme_page.position).to eq(0)
        expect(readme_page.processed_html).to include("Updated markdown")
      end

      it "updates a custom org page's title, markdown, slug, and position" do
        custom_page = create(:page, organization: organization, slug: "#{organization.slug}/about",
                                    template: "full_within_layout", position: 1)

        put api_page_path(custom_page.id),
            params: {
              title: "Our Story",
              slug: "story",
              position: 2,
              body_markdown: "# Story"
            }.to_json,
            headers: org_auth_header

        expect(response).to have_http_status(:ok)
        custom_page.reload
        expect(custom_page.title).to eq("Our Story")
        expect(custom_page.slug).to eq("#{organization.slug}/story")
        expect(custom_page.position).to eq(2)
      end

      it "deletes an organization page" do
        expect do
          delete api_page_path(readme_page.id), headers: org_auth_header
        end.to change(Page, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end

    it "forbids creating, updating, or deleting pages for another organization or global pages" do
      other_org = create(:organization)
      FeatureFlag.enable(:org_readme, FeatureFlag::Actor[other_org])
      other_org_page = create(:page, organization: other_org, slug: "#{other_org.slug}/readme")

      post api_pages_path,
           params: { organization_id: other_org.id, title: "Nope", body_markdown: "# Nope" }.to_json,
           headers: org_auth_header
      expect(response).to have_http_status(:unauthorized)

      put api_page_path(other_org_page.id),
          params: { title: "Nope" }.to_json,
          headers: org_auth_header
      expect(response).to have_http_status(:unauthorized)

      put api_page_path(page.id),
          params: { title: "Nope" }.to_json,
          headers: org_auth_header
      expect(response).to have_http_status(:unauthorized)

      delete api_page_path(other_org_page.id), headers: org_auth_header
      expect(response).to have_http_status(:unauthorized)

      delete api_page_path(page.id), headers: org_auth_header
      expect(response).to have_http_status(:unauthorized)
    ensure
      FeatureFlag.disable(:org_readme, FeatureFlag::Actor[other_org])
    end
  end
end
