require "rails_helper"

RSpec.describe "Dashboards" do
  let(:user)          { create(:user) }
  let(:second_user)   { create(:user) }
  let(:super_admin)   { create(:user, :super_admin) }
  let(:article)       { create(:article, user: user) }
  let(:unpublished_article) { create(:article, user: user, published: false) }
  let(:scheduled_article) { create(:article, user: user, published_at: 2.days.from_now) }
  let(:organization) { create(:organization) }

  describe "GET /dashboard" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard"
        expect(response).to redirect_to("/magic_links/new")
      end
    end

    context "when logged in" do
      before do
        sign_in user
      end

      it "renders user's articles, stats link, analytics link, and no pagination for a single page",
         :aggregate_failures do
        article
        get "/dashboard"

        expect(response.body).to include(CGI.escapeHTML(article.title))
        expect(response.body).to include("Stats")
        expect(response.body).to include("#{article.path}/stats")
        expect(response.body).to include("Analytics")
        expect(response.body).not_to include("pagination")
      end

      it "renders the draft state indicator and delete button for drafts", :aggregate_failures do
        unpublished_article
        get "/dashboard"

        expect(response.body).to include("Draft")
        expect(response.body).to include("Delete")
      end

      it "renders the scheduled state indicator and delete button for scheduled articles", :aggregate_failures do
        scheduled_article
        get "/dashboard"

        expect(response.body).to include("Scheduled")
        expect(response.body).to include("Delete")
      end

      it "renders the detected language if an article has it", :aggregate_failures do
        article.update_column(:language, :es)
        get "/dashboard"

        expect(response.body).to include("Language:")
        expect(response.body).to include("Spanish")
      end

      it "renders subscriptions for articles with subscriptions" do
        allow(user).to receive(:has_role?).and_call_original
        allow(user).to receive(:has_role?).with(:restricted_liquid_tag,
                                                LiquidTags::UserSubscriptionTag).and_return(true)
        article_with_user_subscription_tag = create(:article, user: user, with_user_subscription_tag: true)
        create(:user_subscription,
               subscriber_id: second_user.id,
               subscriber_email: second_user.email,
               author_id: article_with_user_subscription_tag.user_id,
               user_subscription_sourceable: article_with_user_subscription_tag)

        get "/dashboard"
        expect(response.body).to include "Subscriptions"
      end

      it "renders pagination if minimum amount of posts" do
        stub_const("DashboardsController::ARTICLES_PER_PAGE", 2)
        create_list(:article, 3, user: user)
        get "/dashboard"
        expect(response.body).to include "pagination"
      end

      it "does not render a link to upload a video when enable_video_upload is false or for a recent user",
         :aggregate_failures do
        allow(Settings::General).to receive(:enable_video_upload).and_return(false)
        get dashboard_path
        expect(response.body).not_to include("Upload a video")

        allow(Settings::General).to receive(:enable_video_upload).and_return(true)
        get dashboard_path
        expect(response.body).not_to include("Upload a video")
      end
    end

    context "when logged in with many archived posts" do
      before do
        stub_const("DashboardsController::ARTICLES_PER_PAGE", 2)
        sign_in user

        2.times do |i|
          create(:article, user: user, title: "Archived Post #{i}", archived: true,
                           created_at: Time.current - i.minutes)
        end

        3.times do |i|
          create(:article, user: user, title: "Visible Post #{i}", created_at: 1.day.ago - i.minutes)
        end
      end

      it "shows unarchived posts on the first page and remaining on the next page", :aggregate_failures do
        get "/dashboard"

        expect(response.body).to include("Visible Post 0", "Visible Post 1")
        expect(response.body).not_to include("Archived Post 0", "Visible Post 2")
        expect(response.body.scan("spec__dashboard-story").size).to eq(2)

        get "/dashboard", params: { page: 2 }

        expect(response.body).to include("Visible Post 2")
        expect(response.body).not_to include("Archived Post 0")
      end

      it "shows only archived posts when using archived filter", :aggregate_failures do
        get "/dashboard", params: { filter: "archived" }

        expect(response.body).to include("Archived Post 0", "Archived Post 1")
        expect(response.body).not_to include("Visible Post 0")

        html = Nokogiri::HTML(response.body)
        expect(html.css(".story-archived")).to be_present
        expect(html.css(".story-archived.hidden")).to be_empty
      end
    end

    context "when logged but has no articles nor can create them" do
      it "redirects to /dashboard/following_tags" do
        sign_in user

        # [@jeremyf] I'm choosing not to setup the exact conditions of the data for this to be true.
        # Instead, I'm relying on that function to already be tested.
        #
        # rubocop:disable RSpec/AnyInstance
        # Pundit does not make it easy to stub the policy().method questions so I'm using the any instance antics.
        allow_any_instance_of(ArticlePolicy)
          .to receive(:has_existing_articles_or_can_create_new_ones?)
          .and_return(false)
        # rubocop:enable RSpec/AnyInstance

        get dashboard_path
        expect(response).to redirect_to("/dashboard/following_tags")
      end
    end

    context "when logged in with only draft articles and cannot create new ones" do
      it "does not redirect away from the dashboard" do
        sign_in user
        unpublished_article
        allow(ArticlePolicy).to receive(:limit_post_creation_to_admins?).and_return(true)

        get dashboard_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(CGI.escapeHTML(unpublished_article.title))
      end
    end

    describe "sidebar sidebar fetch" do
      it "assigns the agent_sessions_count utilizing the counter cache" do
        sign_in user
        user.reload.update!(agent_sessions_count: 5)

        get "/dashboard/sidebar", params: { state: "show" }, xhr: true

        expect(assigns(:agent_sessions_count)).to eq(5)
      end

      it "assigns posts_count based on non-archived full posts only, ignoring statuses and archived posts" do
        sign_in user
        create(:article, user: user)
        create(:article, user: user, type_of: "status", body_markdown: "", main_image: nil)
        create(:article, user: user, archived: true)

        get "/dashboard/sidebar", params: { state: "show" }, xhr: true

        expect(assigns(:posts_count)).to eq(1)
        expect(response.body).to include('<span class="c-indicator">1</span>')
      end

      it "renders a link to analytics for an admin organization and upload video for eligible users",
         :aggregate_failures do
        create(:organization_membership, type_of_user: :admin, organization: organization, user: user)
        Timecop.freeze(Time.current) do
          user.update!(created_at: 3.weeks.ago)
          allow(Settings::General).to receive(:enable_video_upload).and_return(true)

          sign_in user
          get "/dashboard/sidebar", params: { state: "show" }, xhr: true

          expect(response.body).to include(CGI.escapeHTML("Analytics for #{organization.name}"))
          expect(response.body).to include("Upload a video")
        end
      end

      it "consolidates organization analytics links into a collapsible menu when user has admin orgs" do
        org_one = create(:organization, name: "The DEV Team")
        org_two = create(:organization, name: "CodeNewbie")
        create(:organization_membership, user: user, organization: org_one, type_of_user: "admin")
        create(:organization_membership, user: user, organization: org_two, type_of_user: "admin")

        sign_in user
        get "/dashboard/sidebar", params: { state: "show" }, xhr: true

        html = Nokogiri::HTML(response.body)
        org_menu = html.at_css("details.dashboard-sidebar-orgs[data-sidebar-org-menu]")
        expect(org_menu).to be_present
        expect(org_menu.at_css("summary").text).to include("Organization Analytics")
        expect(org_menu.css("a").map { |a| a.attr("href") }).to contain_exactly(
          "/dashboard/analytics/org/#{org_one.id}",
          "/dashboard/analytics/org/#{org_two.id}",
        )
      end

      it "does not render the organization analytics menu when user has no admin orgs" do
        sign_in user
        get "/dashboard/sidebar", params: { state: "show" }, xhr: true

        html = Nokogiri::HTML(response.body)
        expect(html.at_css("details.dashboard-sidebar-orgs")).to be_nil
      end
    end

    context "when logged in as a super admin" do
      it "renders the specified user's articles" do
        article
        user
        sign_in super_admin
        get "/dashboard/#{user.username}"
        expect(response.body).to include(CGI.escapeHTML(article.title))
      end
    end
  end

  describe "GET /dashboard for spam-flagged and suspended accounts" do
    let(:notice_selector) { "[data-testid='suspended-account-notice']" }
    let(:write_action_hrefs) do
      ["#{article.path}/edit", "#{article.path}/manage", "#{unpublished_article.path}/edit"]
    end

    %i[spam suspended].each do |role|
      context "when the user has the #{role} role" do
        before do
          article
          unpublished_article
          user.add_role(role)
          sign_in user
        end

        it "renders the dashboard with existing posts and an appeal banner instead of a 404", :aggregate_failures do
          get dashboard_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(CGI.escapeHTML(article.title), CGI.escapeHTML(unpublished_article.title))

          notice = Nokogiri::HTML(response.body).at_css(notice_selector)
          expect(notice["data-account-status"]).to eq(role.to_s)
          expect(notice.at_css("a[href='#{appeal_path}']")).to be_present
        end

        it "hides write actions but keeps read-only links such as stats", :aggregate_failures do
          get dashboard_path

          page = Nokogiri::HTML(response.body)
          write_action_hrefs.each { |href| expect(page.at_css("a[href='#{href}']")).to be_nil }
          expect(page.at_css("form.js-archive-toggle")).to be_nil
          expect(page.at_css("a[href='#{article.path}/stats']")).to be_present
        end

        it "shows the banner on the other dashboard views", :aggregate_failures do
          [dashboard_following_tags_path, dashboard_following_users_path, dashboard_hidden_tags_path].each do |path|
            get path

            expect(response).to have_http_status(:ok)
            expect(Nokogiri::HTML(response.body).at_css("#{notice_selector} a[href='#{appeal_path}']")).to be_present
          end
        end

        it "does not raise when every post is archived and the empty state hides the new post link",
           :aggregate_failures do
          article.update_columns(archived: true)
          unpublished_article.update_columns(archived: true)

          get dashboard_path

          expect(response).to have_http_status(:ok)
          expect(Nokogiri::HTML(response.body).at_css("main#main-content a[href='/new']")).to be_nil
        end

        it "renders the desktop and mobile dashboard sidebars without raising when video uploads are enabled",
           :aggregate_failures do
          user.update_columns(created_at: 3.weeks.ago)
          allow(Settings::General).to receive(:enable_video_upload).and_return(true)

          get "/dashboard/sidebar", params: { state: "show" }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include(dashboard_following_tags_path)
          expect(response.body).not_to include(new_video_path)

          get "/dashboard/sidebar", params: { type_of: "mobile", state: "show" }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("/dashboard/following_tags")
          expect(response.body).not_to include(new_video_path)
        end

        it "still forbids creating, editing and deleting posts", :aggregate_failures do
          get "/new"
          expect(response).to have_http_status(:forbidden)

          get "#{article.path}/edit"
          expect(response).to have_http_status(:forbidden)

          get "#{article.path}/manage"
          expect(response).to have_http_status(:forbidden)

          get "#{article.path}/delete_confirm"
          expect(response).to have_http_status(:forbidden)

          expect { delete article_path(article.id) }.not_to change(Article, :count)
          expect(response).to have_http_status(:forbidden)

          expect do
            post articles_path, params: { article: { title: "New", body_markdown: "Hello", published: true } }
          end.not_to change(Article, :count)
          expect(response).to have_http_status(:forbidden)
        end

        it "still lets the user reach the appeal form", :aggregate_failures do
          get appeal_path

          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "when linking post titles on the read-only dashboard" do
      let(:title_hrefs) do
        Nokogiri::HTML(response.body).css(".dashboard-story__title h3 a").pluck("href")
      end

      before do
        article
        unpublished_article
        sign_in user
      end

      it "links a spam author's titles to stats, since their posts 404 for non-admins", :aggregate_failures do
        user.add_role(:spam)

        get dashboard_path

        expect(title_hrefs).to contain_exactly("#{article.path}/stats", "#{unpublished_article.path}/stats")

        get title_hrefs.first
        expect(response).to have_http_status(:ok)
      end

      it "keeps linking a suspended author's titles to their posts", :aggregate_failures do
        user.add_role(:suspended)

        get dashboard_path

        expect(title_hrefs).to contain_exactly(article.current_state_path, unpublished_article.current_state_path)
      end
    end

    context "when a spam-flagged user has no posts" do
      it "redirects to following tags (not a 404) where the appeal banner is shown", :aggregate_failures do
        user.add_role(:spam)
        sign_in user

        get dashboard_path
        expect(response).to redirect_to(dashboard_following_tags_path)

        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(Nokogiri::HTML(response.body).at_css("#{notice_selector}[data-account-status='spam']")).to be_present
      end
    end

    context "when the user is in good standing" do
      before do
        article
        unpublished_article
        sign_in user
      end

      it "keeps write actions and shows no banner", :aggregate_failures do
        get dashboard_path

        page = Nokogiri::HTML(response.body)
        expect(page.at_css(notice_selector)).to be_nil
        expect(page.at_css("a[href='#{article.path}/edit']")).to be_present
        expect(page.at_css("a[href='#{article.path}/manage']")).to be_present
        expect(page.at_css("form.js-archive-toggle")).to be_present
      end
    end
  end

  describe "GET /dashboard/organization" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard/organization"
        expect(response).to redirect_to("/magic_links/new")
      end
    end

    context "when logged in" do
      it "renders user's organization articles and hides archived organization articles", :aggregate_failures do
        create(:organization_membership, user: user, organization: organization, type_of_user: "admin")
        create(:article, user: user, organization_id: organization.id, archived: true)
        sign_in user
        get "/dashboard/organization/#{organization.id}"

        expect(response.body).to include("crayons-logo")
        html = Nokogiri::HTML(response.body)
        expect(html.css(".story-archived.hidden")).to be_present
      end

      it "does not render the delete button for other org member's drafts" do
        create(:organization_membership, user: user, organization: organization, type_of_user: "member")
        create(:organization_membership, user: second_user, organization: organization, type_of_user: "admin")
        unpublished_article.update(organization_id: organization.id)
        sign_in second_user
        get "/dashboard/organization/#{organization.id}"
        expect(response.body).not_to include("Delete")
        expect(response.body).to include(ERB::Util.html_escape(unpublished_article.title))
      end
    end

    context "when logged in but not member of org" do
      it "renders unauthorized" do
        sign_in user
        expect do
          get "/dashboard/organization/#{organization.id}"
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /dashboard/following" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard/following"
        expect(response).to redirect_to("/magic_links/new")
      end
    end

    describe "followed users section" do
      it "lists followed users without issuing a redundant EXISTS query or raw created_at index scan",
         :aggregate_failures do
        sign_in user
        user.follow second_user
        user.reload

        follows_queries = []
        callback = lambda do |*, payload|
          sql = payload[:sql]
          follows_queries << sql if sql.include?('FROM "follows"') && payload[:name] != "SCHEMA"
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get "/dashboard/following_users"
        end

        expect(response.body).to include CGI.escapeHTML(second_user.name)
        expect(follows_queries.grep(/SELECT 1 AS one FROM "follows"/)).to be_empty
        expect(follows_queries.size).to eq(1)
        expect(follows_queries.first).to include("(follows.created_at + INTERVAL '0 seconds') DESC")
      end
    end

    context "when dealing with tags" do
      let(:first_followed_tag) { create(:tag, name: "tagone") }
      let(:antifollowed_tag) { create(:tag, name: "tagtwo") }
      let(:second_followed_tag) { create(:tag, name: "tagthree") }

      before do
        sign_in user
        first_followed = user.follow(first_followed_tag)
        first_followed.update explicit_points: 5

        antifollowed = user.follow(antifollowed_tag)
        antifollowed.update explicit_points: -5

        second_followed = user.follow(second_followed_tag)
        second_followed.update explicit_points: 0
        user.reload
      end

      it "lists followed tags on following_tags and hidden tags on hidden_tags", :aggregate_failures do
        follows_queries = []
        callback = lambda do |*, payload|
          sql = payload[:sql]
          follows_queries << sql if sql.include?('FROM "follows"') && payload[:name] != "SCHEMA"
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get "/dashboard/following_tags"
        end

        expect(response.body).to include first_followed_tag.name
        expect(response.body).to include second_followed_tag.name
        expect(response.body).not_to include antifollowed_tag.name
        expect(follows_queries.grep(/SELECT 1 AS one FROM "follows"/)).to be_empty
        expect(follows_queries.size).to eq(1)
        expect(follows_queries.first).to include('"follows"."points" DESC')

        follows_queries.clear
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get "/dashboard/hidden_tags"
        end

        expect(response.body).not_to include first_followed_tag.name
        expect(response.body).not_to include second_followed_tag.name
        expect(response.body).to include antifollowed_tag.name
        expect(follows_queries.grep(/SELECT 1 AS one FROM "follows"/)).to be_empty
        expect(follows_queries.size).to eq(1)
        expect(follows_queries.first).to include('"follows"."explicit_points" DESC')
      end
    end

    describe "followed organizations section" do
      it "lists followed organizations" do
        sign_in user
        user.follow organization
        user.reload
        get "/dashboard/following_organizations"

        expect(response.body).to include CGI.escapeHTML(organization.name)
      end
    end

    describe "followed podcasts section" do
      let(:podcast) { create(:podcast) }

      it "lists followed podcasts" do
        sign_in user
        user.follow podcast
        user.reload
        get "/dashboard/following_podcasts"

        expect(response.body).to include podcast.name
      end
    end
  end

  describe "GET /dashboard/user_followers" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard/user_followers"
        expect(response).to redirect_to("/magic_links/new")
      end
    end

    context "when logged in" do
      let(:spam_user) { create(:user, :spam) }
      let(:suspended_user) { create(:user, :suspended) }
      let(:blocked_user) { create(:user) }

      before do
        second_user.follow user
        spam_user.follow user
        suspended_user.follow user
        create(:follow, follower: blocked_user, followable: user, blocked: true)
        sign_in user
      end

      it "only includes good standing users as followers without a redundant EXISTS query", :aggregate_failures do
        follows_queries = []
        callback = lambda do |*, payload|
          sql = payload[:sql]
          follows_queries << sql if sql.include?('FROM "follows"') && payload[:name] != "SCHEMA"
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get "/dashboard/user_followers"
        end

        expect(response.body).to include CGI.escapeHTML(second_user.name)
        expect(response.body).not_to include CGI.escapeHTML(spam_user.name)
        expect(response.body).not_to include CGI.escapeHTML(suspended_user.name)
        expect(response.body).not_to include CGI.escapeHTML(blocked_user.name)
        expect(follows_queries.grep(/SELECT 1 AS one FROM "follows"/)).to be_empty
        expect(follows_queries.size).to eq(1)
        expect(follows_queries.first).to match(/"follows"\."blocked" = (FALSE|\$\d+)/)
      end
    end
  end

  describe "GET /dashboard/analytics" do
    context "when not logged in" do
      it "raises unauthorized" do
        get "/dashboard/analytics"
        expect(response).to redirect_to("/magic_links/new")
      end
    end

    context "when user is signed in" do
      it "shows page properly and contains back to dashboard button", :aggregate_failures do
        sign_in user
        get "/dashboard/analytics"
        expect(response.body).to include("Analytics")
        within "nav" do
          expect(page).to have_link(href: "/dashboard")
        end
      end
    end

    context "when user is an org admin or member" do
      it "shows page properly for admin and member roles and consolidates orgs into the switcher menu",
         :aggregate_failures do
        other_org = create(:organization, name: "AI Pulse")
        membership = create(:organization_membership, user: user, organization: organization, type_of_user: "admin")
        create(:organization_membership, user: user, organization: other_org)

        sign_in user
        get "/dashboard/analytics/org/#{organization.id}"
        expect(response.body).to include("Analytics")

        membership.update!(type_of_user: "member")
        get "/dashboard/analytics/org/#{organization.id}"
        expect(response.body).to include("Analytics")

        html = Nokogiri::HTML(response.body)
        org_menu = html.at_css("details.analytics-org-menu[data-analytics-org-menu]")
        expect(org_menu).to be_present
        expect(org_menu.at_css("summary.is-active").text).to include(organization.name)
        active_link = org_menu.at_css('a[aria-current="page"]')
        expect(active_link["data-organization-id"]).to eq(organization.id.to_s)
      end
    end
  end

  describe "GET /dashboard/feed_imports" do
    context "when not logged in" do
      it "redirects to /enter" do
        get "/dashboard/feed_imports"
        expect(response).to redirect_to("/magic_links/new")
      end
    end

    context "when logged in" do
      before do
        sign_in user
      end

      it "renders successfully with add source form when no sources exist", :aggregate_failures do
        get "/dashboard/feed_imports"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Add a Feed Source")
        expect(response.body).to include("Publishing from RSS")
      end

      it "renders existing feed sources with edit controls and empty import state when no imports exist",
         :aggregate_failures do
        allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
        create(:feed_source, user: user, name: "My Blog", feed_url: "https://example.com/feed.xml")

        get "/dashboard/feed_imports"
        expect(response.body).to include("My Blog")
        expect(response.body).to include("Your Feed Sources")
        expect(response.body).to include("Edit")
        expect(response.body).to include("No import history yet")
      end

      it "shows health warning when feed is degraded or failing", :aggregate_failures do
        allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
        source = create(:feed_source, user: user, feed_url: "https://example.com/feed.xml", status: :degraded)

        get "/dashboard/feed_imports"
        expect(response.body).to include("recent failures")

        source.update!(status: :failing)
        get "/dashboard/feed_imports"
        expect(response.body).to include("failing consistently")
      end

      it "shows import history and skipped items in collapsible section on first-time logs", :aggregate_failures do
        allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
        source = create(:feed_source, user: user, feed_url: "https://example.com/feed.xml")
        log = create(:feed_import_log, user: user, feed_source: source,
                                       items_imported: 1, items_skipped: 3)
        create(:feed_import_item, :imported, import_log: log, article: article, feed_item_title: "My New Article")
        create_list(:feed_import_item, 3, :skipped, import_log: log)

        get "/dashboard/feed_imports"

        expect(response.body).to include("Completed")
        expect(response.body).to include("My New Article")
        expect(response.body).to include("Show 3 skipped duplicates")
      end

      it "shows skipped count in summary even without individual skip items" do
        allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
        source = create(:feed_source, user: user, feed_url: "https://example.com/feed.xml")
        create(:feed_import_log, user: user, feed_source: source,
                                 items_imported: 0, items_skipped: 5)

        get "/dashboard/feed_imports"

        expect(response.body).to include("5")
      end
    end
  end

  describe "GET /dashboard/subscriptions" do
    let(:author) { create(:user) }
    let(:article_with_user_subscription_tag) { create(:article, user: author, with_user_subscription_tag: true) }
    let(:params) do
      { source_type: article_with_user_subscription_tag.class.name, source_id: article_with_user_subscription_tag.id }
    end

    before do
      # Stub roles because adding them normally can cause flaky specs
      allow(author).to receive(:has_role?).and_call_original
      allow(author).to receive(:has_role?).with(:restricted_liquid_tag,
                                                LiquidTags::UserSubscriptionTag).and_return(true)

      sign_in author
    end

    it "renders subscriptions with page heading, subscriber links, and no pagination for a single page",
       :aggregate_failures do
      user_subscription = create(:user_subscription,
                                 subscriber_id: second_user.id,
                                 subscriber_email: second_user.email,
                                 author_id: article_with_user_subscription_tag.user_id,
                                 user_subscription_sourceable: article_with_user_subscription_tag)

      get "/dashboard/subscriptions", params: params
      expect(response.body).to include(user_subscription.subscriber_email)
      expect(response.body).not_to include("pagination")

      html = Nokogiri::HTML(response.body)
      heading = html.at_css("h1.crayons-title")
      expect(heading.text.strip).to eq(I18n.t("views.dashboard.subscriptions.heading"))

      profile_link = html.at_css("td.fw-medium a")
      expect(profile_link[:href]).to eq(user_profile_path(second_user.username))
      expect(profile_link.text.strip).to eq(second_user.name)
      expect(profile_link.attributes.keys).to eq(["href"])

      mailto_link = html.at_css("a[href^='mailto:']")
      expect(mailto_link[:href]).to eq("mailto:#{user_subscription.subscriber_email}")
    end

    it "displays a message if no subscriptions are found" do
      get "/dashboard/subscriptions", params: params
      expect(response.body).to include(CGI.escapeHTML("You don't have any subscribers for this"))
    end

    it "raises unauthorized when trying to access a source the user doesn't own" do
      unauthorized_article = create(:article, user: second_user)
      unauthorized_article_params = { source_type: unauthorized_article.class.name, source_id: unauthorized_article.id }

      expect do
        get "/dashboard/subscriptions", params: unauthorized_article_params
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    it "raises an error for disallowed source_types or when the source can't be found", :aggregate_failures do
      expect do
        get "/dashboard/subscriptions", params: { source_type: "Comment", source_id: 1 }
      end.to raise_error(ActiveRecord::RecordNotFound)

      expect do
        get "/dashboard/subscriptions", params: { source_type: "Article", source_id: 0 }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "renders pagination if minimum amount of subscriptions" do
      allow(UserSubscription).to receive(:max_per_page).and_return(2)
      now = Time.current
      records = Array.new(3) do |i|
        {
          author_id: author.id,
          subscriber_id: second_user.id,
          subscriber_email: "subscriber-#{i}@example.com",
          user_subscription_sourceable_type: article_with_user_subscription_tag.class.name,
          user_subscription_sourceable_id: article_with_user_subscription_tag.id,
          created_at: now,
          updated_at: now
        }
      end
      UserSubscription.insert_all!(records)

      get "/dashboard/subscriptions", params: params
      expect(response.body).to include "pagination"
    end
  end
end
