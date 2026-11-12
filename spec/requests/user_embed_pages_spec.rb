require "rails_helper"

RSpec.describe "User Sandboxed HTML Embed Pages" do
  let(:user) { create(:user, username: "alicebuilder", name: "Alice Builder") }
  let(:other_user) { create(:user, username: "bobviewer", name: "Bob Viewer") }
  let(:custom_html) do
    <<~HTML
      <!DOCTYPE html>
      <html>
        <body>
          <div id="demo-widget">Interactive Shader Demo</div>
          <script>document.getElementById("demo-widget").dataset.booted = "1";</script>
        </body>
      </html>
    HTML
  end

  before do
    FeatureFlag.add(:user_embed_pages)
  end

  after do
    FeatureFlag.disable(:user_embed_pages)
    FeatureFlag.disable(:user_embed_pages, user)
    FeatureFlag.disable(:user_embed_pages, FeatureFlag::Actor[user])
  end

  describe "feature flag gating and dashboard navigation" do
    it "hides the dashboard link and returns 404 on management and embed routes when disabled", :aggregate_failures do
      embed_page = create(
        :page,
        user: user,
        title: "Hidden Widget",
        description: "desc",
        slug: "#{user.username}/embed/hidden-widget",
        template: "embed_html",
        body_markdown: nil,
        body_html: custom_html,
      )

      sign_in user
      get "/dashboard/sidebar"
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("/dashboard/embed_pages")

      expect do
        get "/dashboard/embed_pages"
      end.to raise_error(ActiveRecord::RecordNotFound)

      get "/#{embed_page.slug}", params: { mode: "embed" }, headers: { "Sec-Fetch-Dest" => "iframe" }
      expect(response).to have_http_status(:not_found)
    end

    it "displays the Embedded Pages link in the dashboard when enabled per-user or globally", :aggregate_failures do
      create(:article, user: user, published: true)
      FeatureFlag.enable(:user_embed_pages, FeatureFlag::Actor[user])

      sign_in user
      get "/dashboard"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("/dashboard/embed_pages")
      expect(response.body).to include(I18n.t("views.dashboard.actions.embed_pages"))

      get "/dashboard/sidebar", params: { state: "embed_pages" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("/dashboard/embed_pages")
      expect(response.body).to include("crayons-link--current")
    end

    it "also supports enabling the Flipper flag directly with the User actor", :aggregate_failures do
      FeatureFlag.enable(:user_embed_pages, user)
      expect(user.embed_pages_enabled?).to be(true)
      expect(user.can_manage_embed_pages?).to be(true)
      expect(user.can_serve_embed_pages?).to be(true)
    end
  end

  describe "dashboard CRUD (/dashboard/embed_pages)" do
    before do
      FeatureFlag.enable(:user_embed_pages, FeatureFlag::Actor[user])
      sign_in user
    end

    it "creates, edits, lists, and deletes user embed_html pages while forcing template", :aggregate_failures do
      expect do
        post "/dashboard/embed_pages", params: {
          page: {
            title: "Sorting Visualizer",
            slug_suffix: "Sorting Visualizer!",
            description: "Interactive sorting canvas",
            template: "full_within_layout",
            body_html: custom_html
          }
        }
      end.to change { user.pages.embed_html.count }.by(1)

      expect(response).to redirect_to("/dashboard/embed_pages")
      page = user.pages.embed_html.last
      expect(page.slug).to eq("#{user.username}/embed/sorting-visualizer")
      expect(page.template).to eq("embed_html")
      expect(page.organization_id).to be_nil
      expect(page.is_top_level_path).to be(false)

      get "/dashboard/embed_pages"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sorting Visualizer")
      expect(response.body).to include("{% embed #{URL.url("/#{user.username}/embed/sorting-visualizer")} %}")

      patch "/dashboard/embed_pages/#{page.id}", params: {
        page: {
          title: "Updated Visualizer",
          slug_suffix: "updated-visualizer",
          description: "Updated desc",
          body_html: "<p>Updated</p>"
        }
      }
      expect(response).to redirect_to("/dashboard/embed_pages")
      expect(page.reload.slug).to eq("#{user.username}/embed/updated-visualizer")
      expect(page.title).to eq("Updated Visualizer")

      expect do
        delete "/dashboard/embed_pages/#{page.id}"
      end.to change { user.pages.embed_html.count }.by(-1)
      expect(response).to redirect_to("/dashboard/embed_pages")
    end

    it "prevents another user from editing, updating, or deleting a user's embed page", :aggregate_failures do
      FeatureFlag.enable(:user_embed_pages, FeatureFlag::Actor[other_user])
      own_page = create(
        :page,
        user: user,
        title: "Alice Private Manage",
        description: "desc",
        slug: "#{user.username}/embed/alice-only",
        template: "embed_html",
        body_markdown: nil,
        body_html: custom_html,
      )

      sign_in other_user

      expect do
        get "/dashboard/embed_pages/#{own_page.id}/edit"
      end.to raise_error(ActiveRecord::RecordNotFound)

      expect do
        patch "/dashboard/embed_pages/#{own_page.id}", params: {
          page: { title: "Hijack", slug_suffix: "hijack", body_html: "<p>bad</p>" }
        }
      end.to raise_error(ActiveRecord::RecordNotFound)

      expect do
        delete "/dashboard/embed_pages/#{own_page.id}"
      end.to raise_error(ActiveRecord::RecordNotFound)
      expect(Page.exists?(own_page.id)).to be(true)
    ensure
      FeatureFlag.disable(:user_embed_pages, FeatureFlag::Actor[other_user])
    end

    it "enforces creation rate limits cleanly with 422", :aggregate_failures do
      limiter = instance_double(RateLimitChecker)
      allow(user).to receive(:rate_limiter).and_return(limiter)
      allow(limiter).to receive(:consume!).with(:embed_page_creation)
        .and_raise(RateLimitChecker::LimitReached.new(60))

      post "/dashboard/embed_pages", params: {
        page: {
          title: "Rate Limited Widget",
          slug_suffix: "rate-limited",
          body_html: "<p>Hi</p>"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.pages.embed_html.count).to eq(0)
    end
  end

  describe "model and resource constraints" do
    it "forbids non-embed_html templates for user-owned pages and dual user+org ownership", :aggregate_failures do
      readme_attempt = build(
        :page,
        user: user,
        title: "User Top-Level Attempt",
        description: "desc",
        slug: "#{user.username}/readme",
        template: "full_within_layout",
        body_markdown: "# Not allowed yet",
      )
      expect(readme_attempt).not_to be_valid
      expect(readme_attempt.errors[:template]).to be_present

      org = create(:organization, slug: "dual-owner-org")
      dual_owner_page = build(
        :page,
        user: user,
        organization: org,
        title: "Dual",
        description: "desc",
        slug: "#{org.slug}/embed/dual",
        template: "embed_html",
        body_markdown: nil,
        body_html: "<p>Dual</p>",
      )
      expect(dual_owner_page).not_to be_valid
      expect(dual_owner_page.errors[:base]).to be_present
    end

    it "enforces body_html byte size limit and per-user page count cap", :aggregate_failures do
      oversized = build(
        :page,
        user: user,
        title: "Huge HTML",
        description: "desc",
        slug: "#{user.username}/embed/huge",
        template: "embed_html",
        body_markdown: nil,
        body_html: "a" * (Page::MAX_EMBED_HTML_BYTES + 1),
      )
      expect(oversized).not_to be_valid
      expect(oversized.errors[:body_html]).to be_present

      stub_const("Page::MAX_USER_EMBED_PAGES", 2)
      2.times do |idx|
        create(
          :page,
          user: user,
          title: "Widget #{idx}",
          description: "desc",
          slug: "#{user.username}/embed/widget-#{idx}",
          template: "embed_html",
          body_markdown: nil,
          body_html: "<p>#{idx}</p>",
        )
      end

      over_cap = build(
        :page,
        user: user,
        title: "Widget 3",
        description: "desc",
        slug: "#{user.username}/embed/widget-3",
        template: "embed_html",
        body_markdown: nil,
        body_html: "<p>3</p>",
      )
      expect(over_cap).not_to be_valid
      expect(over_cap.errors[:base]).to be_present
    end
  end

  describe "sandboxed serving, isolation, and moderation safety" do
    let!(:embed_page) do
      create(
        :page,
        user: user,
        title: "Shader Playground",
        description: "Sandboxed WebGL shader playground",
        slug: "#{user.username}/embed/shader-playground",
        template: "embed_html",
        body_markdown: nil,
        body_html: custom_html,
      )
    end

    before do
      FeatureFlag.enable(:user_embed_pages, FeatureFlag::Actor[user])
    end

    it "serves user HTML in an opaque-origin CSP sandbox with zero cookies or session access", :aggregate_failures do
      sign_in other_user

      get "/#{embed_page.slug}",
          params: { mode: "embed" },
          headers: {
            "Sec-Fetch-Dest" => "iframe",
            "Cookie" => "remember_user_token=secret; _Dev_Community_Session=secret"
          }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(custom_html)
      expect(response.headers["Set-Cookie"]).to be_nil

      csp = response.headers["Content-Security-Policy"]
      expect(csp).to include("sandbox #{OrganizationEmbedsController::SANDBOX_DIRECTIVE}")
      expect(csp).not_to include("allow-same-origin")
      expect(csp).not_to include("allow-top-navigation")
      expect(csp).not_to include("allow-modals")
      expect(csp).to include("base-uri 'none'")
      expect(csp).to include("object-src 'none'")
      expect(response.headers["Referrer-Policy"]).to eq("no-referrer")
      expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
      expect(response.headers["Permissions-Policy"]).to include("camera=()", "storage-access=()")
      expect(response.headers["Surrogate-Key"]).to include(
        "show-page-#{embed_page.slug}",
        user.record_key,
        user.profile_identity_record_key,
      )
    end

    it "blocks top-level navigation, missing mode=embed, private Forems, and page/API routes", :aggregate_failures do
      get "/#{embed_page.slug}"
      expect(response).to have_http_status(:not_found)

      get "/#{embed_page.slug}", params: { mode: "embed" }, headers: { "Sec-Fetch-Dest" => "document" }
      expect(response).to have_http_status(:forbidden)
      expect(response.headers["Cache-Control"]).to eq("private, no-store")

      expect do
        get "/page/#{embed_page.slug}"
      end.to raise_error(ActiveRecord::RecordNotFound)

      v1_headers = { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" }
      get api_page_path(embed_page.id), headers: v1_headers
      expect(response).to have_http_status(:not_found)

      allow(Settings::UserExperience).to receive(:public).and_return(false)
      get "/#{embed_page.slug}", params: { mode: "embed" }, headers: { "Sec-Fetch-Dest" => "iframe" }
      expect(response).to have_http_status(:not_found)
    end

    it "stops serving embeds and purges cache when user is suspended or marked spam", :aggregate_failures do
      allow(Users::BustCacheWorker).to receive(:perform_async)
      allow(Pages::BustCacheWorker).to receive(:perform_async)

      user.add_role(:suspended)

      expect(Users::BustCacheWorker).to have_received(:perform_async).with(user.id)
      expect(Pages::BustCacheWorker).to have_received(:perform_async).with(embed_page.slug, nil, user.id)

      get "/#{embed_page.slug}", params: { mode: "embed" }, headers: { "Sec-Fetch-Dest" => "iframe" }
      expect(response).to have_http_status(:not_found)

      sign_in user
      expect do
        get "/dashboard/embed_pages"
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    it "destroys user embed pages when the user account is deleted" do
      page_id = embed_page.id
      user.destroy!
      expect(Page.exists?(page_id)).to be(false)
    end

    it "serves after username rename without legacy usernames shadowing new accounts", :aggregate_failures do
      user.update!(old_username: user.username, username: "alicerenamed")

      get "/alicerenamed/embed/shader-playground",
          params: { mode: "embed" },
          headers: { "Sec-Fetch-Dest" => "iframe" }
      expect(response).to have_http_status(:ok)

      get "/alicebuilder/embed/shader-playground",
          params: { mode: "embed" },
          headers: { "Sec-Fetch-Dest" => "iframe" }
      expect(response).to have_http_status(:ok)

      new_owner = create(:user, username: "alicebuilder")
      FeatureFlag.enable(:user_embed_pages, FeatureFlag::Actor[new_owner])

      get "/alicebuilder/embed/shader-playground",
          params: { mode: "embed" },
          headers: { "Sec-Fetch-Dest" => "iframe" }
      expect(response).to have_http_status(:not_found)
    ensure
      FeatureFlag.disable(:user_embed_pages, FeatureFlag::Actor[new_owner]) if new_owner
    end
  end
end
