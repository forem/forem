require "rails_helper"

RSpec.describe "Organization Sandboxed HTML Embeds" do
  let(:organization) { create(:organization, slug: "acme-widgets") }
  let(:custom_html) do
    <<~HTML
      <!DOCTYPE html>
      <html>
        <head><style>body { color: rebeccapurple; }</style></head>
        <body>
          <div id="widget-root">Interactive ROI Calculator</div>
          <script>document.getElementById("widget-root").dataset.ready = "true";</script>
        </body>
      </html>
    HTML
  end
  let!(:embed_page) do
    create(
      :page,
      organization: organization,
      title: "ROI Calculator",
      description: "Sandboxed calculator widget",
      slug: "#{organization.slug}/embed/roi-calculator",
      template: "embed_html",
      body_markdown: nil,
      body_html: custom_html,
    )
  end

  before do
    FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization])
  end

  after do
    FeatureFlag.disable(:org_readme, FeatureFlag::Actor[organization])
  end

  describe "security invariants" do
    it "never permits dangerous sandbox flags or session/cookie controller modules", :aggregate_failures do
      forbidden_flags = %w[
        allow-same-origin
        allow-top-navigation
        allow-top-navigation-by-user-activation
        allow-top-navigation-to-custom-protocols
        allow-modals
        allow-pointer-lock
        allow-storage-access-by-user-activation
      ]

      [OrganizationEmbedsController::SANDBOX_DIRECTIVE, PageTag::IFRAME_SANDBOX].each do |directive|
        tokens = directive.split
        forbidden_flags.each do |flag|
          expect(tokens).not_to include(flag)
        end
      end

      expect(OrganizationEmbedsController.ancestors).not_to include(
        ApplicationController,
        ActionController::Cookies,
        SessionCurrentUser,
      )
    end

    it "prevents mutating template to or from embed_html on existing pages", :aggregate_failures do
      markdown_page = create(
        :page,
        organization: organization,
        slug: "#{organization.slug}/about",
        template: "full_within_layout",
        body_markdown: "# About",
      )

      markdown_page.template = "embed_html"
      markdown_page.slug = "#{organization.slug}/embed/about"
      markdown_page.body_html = "<p>Hi</p>"
      expect(markdown_page).not_to be_valid
      expect(markdown_page.errors[:template]).to be_present

      embed_page.template = "full_within_layout"
      expect(embed_page).not_to be_valid
      expect(embed_page.errors[:template]).to be_present
    end

    it "does not execute server-side Liquid tags inside embed_html body_html" do
      liquid_embed_page = create(
        :page,
        organization: organization,
        title: "Raw Liquid Test",
        description: "desc",
        slug: "#{organization.slug}/embed/raw-liquid",
        template: "embed_html",
        body_markdown: nil,
        body_html: "<p>{% org_posts #{organization.slug} %}</p>",
      )

      expect(liquid_embed_page.processed_html).to eq("<p>{% org_posts #{organization.slug} %}</p>")
    end

    it "rejects blank slugs on embed_html pages" do
      invalid_page = build(
        :page,
        organization: organization,
        title: "Missing Slug",
        description: "desc",
        slug: nil,
        template: "embed_html",
        body_markdown: nil,
        body_html: "<p>Hello</p>",
      )

      expect(invalid_page).not_to be_valid
      expect(invalid_page.errors[:slug]).to be_present
    end
  end

  describe "GET /:org_slug/embed/:slug_suffix" do
    it "serves raw HTML inside a strict opaque-origin CSP sandbox when requested for an iframe", :aggregate_failures do
      viewer = create(:user)
      sign_in viewer

      get "/#{organization.slug}/embed/roi-calculator",
          params: { mode: "embed" },
          headers: { "Sec-Fetch-Dest" => "iframe" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
      expect(response.body).to start_with("<!DOCTYPE html>")
      expect(response.body).to include('data-forem-embed="1"')
      expect(response.body).to include('data-forem-wrapper-script="1"')
      expect(response.body).to include("<style>body { color: rebeccapurple; }</style>")
      expect(response.body).to include('<div id="widget-root">Interactive ROI Calculator</div>')
      expect(response.body).to include('document.getElementById("widget-root").dataset.ready = "true";')
      expect(response.body.index("data-forem-wrapper-script")).to be < response.body.index('dataset.ready = "true"')
      expect(response.body).not_to include("csrf-token")
      expect(response.body).not_to include("data-user-status")
      expect(response.body).not_to include("crayons-header")
      expect(response.headers["Set-Cookie"]).to be_nil

      csp = response.headers["Content-Security-Policy"]
      expect(csp).to include("sandbox #{OrganizationEmbedsController::SANDBOX_DIRECTIVE}")
      expect(csp).not_to include("allow-same-origin")
      expect(csp).to include("frame-ancestors")
      expect(csp).to include("base-uri 'none'")
      expect(csp).to include("object-src 'none'")
      expect(csp).to include("frame-src 'none'")
      expect(csp).to include("worker-src 'none'")
      expect(csp).to include("form-action 'none'")

      permissions = response.headers["Permissions-Policy"]
      expect(permissions).to include("storage-access=()")
      expect(permissions).to include("identity-credentials-get=()")
      expect(permissions).to include("clipboard-read=()")
      expect(permissions).to include("fullscreen=()")
      expect(permissions).to include("sync-xhr=()")

      expect(response.headers["Referrer-Policy"]).to eq("no-referrer")
      expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
      expect(response.headers["Origin-Agent-Cluster"]).to eq("?1")
      expect(response.headers["Cross-Origin-Opener-Policy"]).to eq("same-origin")
      expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow, noarchive")
      expect(response.headers["X-DNS-Prefetch-Control"]).to eq("off")
      expect(response.headers["Vary"]).to include("Sec-Fetch-Dest", "Sec-Fetch-User")
      expect(response.headers["Surrogate-Key"]).to include(
        "show-page-#{embed_page.slug}",
        "embed-html-wrapper-#{Pages::EmbedHtmlWrapper.wrapper_digest}",
        organization.record_key,
      )
    end

    it "strips dangerous elements and attributes when serving wrapped embed HTML", :aggregate_failures do
      unsafe_page = create(
        :page,
        organization: organization,
        title: "Unsafe Markup",
        description: "desc",
        slug: "#{organization.slug}/embed/unsafe-markup",
        template: "embed_html",
        body_markdown: nil,
        body_html: <<~HTML,
          <base href="https://evil.test/">
          <meta http-equiv="refresh" content="0;url=https://evil.test/">
          <iframe srcdoc="<script>alert(1)</script>"></iframe>
          <a href="https://example.com" ping="https://track.test">Safe</a>
          <input autofocus>
        HTML
      )

      get "/#{unsafe_page.slug}",
          params: { mode: "embed" },
          headers: { "Sec-Fetch-Dest" => "iframe" }

      expect(response).to have_http_status(:ok)
      doc = response.parsed_body
      expect(doc.css("base, iframe")).to be_empty
      expect(doc.css('meta[http-equiv="refresh"]')).to be_empty
      expect(doc.at_css("input")["autofocus"]).to be_nil
      expect(doc.at_css("a")["target"]).to eq("_blank")
      expect(doc.at_css("a")["ping"]).to be_nil
    end

    it "rejects requests missing ?mode=embed without exposing HTML", :aggregate_failures do
      get "/#{organization.slug}/embed/roi-calculator", headers: { "Sec-Fetch-Dest" => "iframe" }

      expect(response).to have_http_status(:not_found)
      expect(response.media_type).to eq("text/plain")
      expect(response.body).not_to include("ROI Calculator")
      expect(response.headers["Cache-Control"]).to eq("private, no-store")
      expect(response.headers["Set-Cookie"]).to be_nil
    end

    it "rejects direct top-level browser navigation, Sec-Fetch-User requests, and non-iframe destinations",
       :aggregate_failures do
      %w[document object embed window frame].each do |dest|
        get "/#{organization.slug}/embed/roi-calculator",
            params: { mode: "embed" },
            headers: { "Sec-Fetch-Dest" => dest }

        expect(response).to have_http_status(:forbidden)
        expect(response.media_type).to eq("text/plain")
        expect(response.body).not_to include("ROI Calculator")
        expect(response.headers["Set-Cookie"]).to be_nil
      end

      get "/#{organization.slug}/embed/roi-calculator",
          params: { mode: "embed" },
          headers: { "Sec-Fetch-User" => "?1" }
      expect(response).to have_http_status(:forbidden)

      get "/#{organization.slug}/embed/roi-calculator",
          params: { mode: "embed" },
          headers: { "Sec-Fetch-Dest" => "iframe", "Sec-Fetch-User" => "?1" }
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 when the org_readme feature flag is disabled" do
      FeatureFlag.disable(:org_readme, FeatureFlag::Actor[organization])

      get "/#{organization.slug}/embed/roi-calculator",
          params: { mode: "embed" },
          headers: { "Sec-Fetch-Dest" => "iframe" }

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include("ROI Calculator")
    end

    it "returns 404 when the Forem instance is private" do
      allow(Settings::UserExperience).to receive(:public).and_return(false)

      get "/#{organization.slug}/embed/roi-calculator",
          params: { mode: "embed" },
          headers: { "Sec-Fetch-Dest" => "iframe" }

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include("ROI Calculator")
    end

    it "serves embeds after an org slug rename and prefers the current slug", :aggregate_failures do
      old_slug = organization.slug
      organization.update!(slug: "acme-renamed")

      get "/#{old_slug}/embed/roi-calculator",
          params: { mode: "embed" },
          headers: { "Sec-Fetch-Dest" => "iframe" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Interactive ROI Calculator")

      create(
        :page,
        organization: organization,
        title: "Replacement Calculator",
        description: "New widget",
        slug: "acme-renamed/embed/roi-calculator",
        template: "embed_html",
        body_markdown: nil,
        body_html: "<div>Replacement Widget</div>",
      )

      get "/acme-renamed/embed/roi-calculator",
          params: { mode: "embed" },
          headers: { "Sec-Fetch-Dest" => "iframe" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<div>Replacement Widget</div>")
    end

    it "preserves article action routes when an article literally has slug 'embed'", :aggregate_failures do
      expect(Rails.application.routes.recognize_path("/alice/embed/edit", method: :get))
        .to include(controller: "articles", action: "edit", username: "alice", slug: "embed")

      create(
        :page,
        organization: organization,
        title: "Edit Widget",
        description: "desc",
        slug: "#{organization.slug}/embed/edit",
        template: "embed_html",
        body_markdown: nil,
        body_html: "<div>Edit Embed Widget</div>",
      )

      get "/#{organization.slug}/embed/edit",
          params: { mode: "embed" },
          headers: { "Sec-Fetch-Dest" => "iframe" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<div>Edit Embed Widget</div>")
    end
  end

  describe "isolation from top-level routes, profile tabs, and public Pages API" do
    it "never renders embed_html pages through PagesController or StoriesController", :aggregate_failures do
      expect do
        get "/page/#{embed_page.slug}"
      end.to raise_error(ActiveRecord::RecordNotFound)

      expect do
        get "/#{organization.slug}/p/roi-calculator"
      end.to raise_error(ActiveRecord::RecordNotFound)

      get "/#{organization.slug}"
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Interactive ROI Calculator")
      expect(response.body).not_to include("ROI Calculator")
    end

    it "hides embed_html pages from the public API v1 pages index and show, but not from org admins",
       :aggregate_failures do
      v1_headers = { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" }

      get api_pages_path, params: { organization_id: organization.id }, headers: v1_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.pluck("id")).not_to include(embed_page.id)

      get api_page_path(embed_page.id), headers: v1_headers
      expect(response).to have_http_status(:not_found)

      org_admin = create(:user)
      create(:organization_membership, user: org_admin, organization: organization, type_of_user: "admin")
      api_secret = create(:api_secret, user: org_admin)

      put api_page_path(embed_page.id),
          params: { title: "Updated through the API" }.to_json,
          headers: v1_headers.merge("api-key" => api_secret.secret)
      expect(response).to have_http_status(:ok)
      expect(embed_page.reload).to have_attributes(title: "Updated through the API", template: "embed_html")
    end
  end

  describe "event-owned sandboxed embed_html pages" do
    let!(:published_event) do
      create(:event, published: true, event_name_slug: "dev-conf", event_variation_slug: "2026")
    end
    let!(:event_embed) do
      create(
        :page,
        event: published_event,
        title: "Event Schedule Widget",
        description: "Interactive schedule",
        slug: published_event.embed_page_slug_for("schedule"),
        template: Page::EMBED_HTML_TEMPLATE,
        body_markdown: nil,
        body_html: "<div>Event Schedule Widget</div>",
      )
    end

    it "serves published event embeds inside the sandboxed controller and rejects direct or draft access",
       :aggregate_failures do
      get event_embed_page_path(published_event.event_name_slug, published_event.event_variation_slug, "schedule"),
          params: { mode: "embed" },
          headers: { "Sec-Fetch-Dest" => "iframe" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<div>Event Schedule Widget</div>")
      expect(response.headers["Content-Security-Policy"]).to include(
        "sandbox #{OrganizationEmbedsController::SANDBOX_DIRECTIVE}",
      )

      get event_embed_page_path(published_event.event_name_slug, published_event.event_variation_slug, "schedule"),
          params: { mode: "embed" },
          headers: { "Sec-Fetch-Dest" => "document" }
      expect(response).to have_http_status(:forbidden)

      published_event.update!(published: false)
      get event_embed_page_path(published_event.event_name_slug, published_event.event_variation_slug, "schedule"),
          params: { mode: "embed" },
          headers: { "Sec-Fetch-Dest" => "iframe" }
      expect(response).to have_http_status(:not_found)
      expect(event_embed.reload.embed_html?).to be(true)
    end
  end
end
