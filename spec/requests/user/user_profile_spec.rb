require "rails_helper"

RSpec.describe "UserProfiles" do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:current_user) { create(:user, :without_profile, profile_image: nil) }

  describe "GET /:username" do
    it "renders the user profile page without noindex or feed link when there are no stories", :aggregate_failures do
      get "/#{user.username}"
      expect(response.body).to include(CGI.escapeHTML(user.name), "More info about @#{user.username}")
      expect(response.body).not_to include('<meta name="robots" content="noindex">', "/feed/#{user.username}")
    end

    it "renders pins if any" do
      last_article = create(:article, user_id: user.id, with_tags: false)
      create(:profile_pin, pinnable: last_article, profile: user)
      get "/#{user.username}"
      expect(response.body).to include "Pinned"
    end

    it "does not render unpublished pinned stories" do
      unpublished_article = create(
        :article, user: user, published: false, published_at: nil, title: "Unpublished Pinned Story", with_tags: false
      )
      create(:profile_pin, pinnable: unpublished_article, profile: user)

      get "/#{user.username}"

      expect(response.body).not_to include("Unpublished Pinned Story")
    end

    context "when user has full_post and status articles" do
      before do
        create(:article, user: user, title: "Super Article", published: true, type_of: "full_post")
        Article.create(
          user: user, title: "Status Update", published: true, type_of: "status", body_markdown: "", main_image: "",
        )
      end

      it "displays only 'full_post' articles and excludes 'status' articles", :aggregate_failures do
        sign_in current_user
        get user.path
        expect(response.body).to include("Super Article")
        expect(response.body).not_to include("Status Update")
      end
    end

    it "counts the user's published articles once for the sidebar stats", :aggregate_failures do
      create(:article, user: user)
      published_count_queries = []
      callback = lambda do |*, payload|
        sql = payload[:sql]
        next unless sql.start_with?('SELECT COUNT(*) FROM "articles" WHERE "articles"."user_id"')
        next unless sql.include?("published_at <=")
        next if sql.match?(/type_of|created_at >|score/)

        published_count_queries << sql
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get "/#{user.username}"
      end

      expect(response.body).to include("1 post published")
      expect(published_count_queries.size).to eq(1)
    end

    it "skips badge_achievements queries when user has no badges", :aggregate_failures do
      badge_queries = []
      callback = lambda do |*, payload|
        sql = payload[:sql]
        badge_queries << sql if sql.include?('"badge_achievements"') || sql.include?('"badges"')
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get "/#{user.username}"
      end

      expect(response).to have_http_status(:ok)
      expect(badge_queries).to be_empty
    end

    it "queries badge_achievements on fragment cache miss and skips on cache hit", :aggregate_failures do
      badge = create(:badge)
      create(:badge_achievement, user: user, badge: badge)
      user.reload

      original_cache_store = ActionController::Base.cache_store
      original_perform_caching = ActionController::Base.perform_caching
      ActionController::Base.cache_store = ActiveSupport::Cache::MemoryStore.new
      ActionController::Base.perform_caching = true

      miss_queries = []
      miss_cb = ->(*, payload) { miss_queries << payload[:sql] if payload[:sql].include?('"badge_achievements"') }
      ActiveSupport::Notifications.subscribed(miss_cb, "sql.active_record") do
        get "/#{user.username}"
      end

      expect(response.body).to include(CGI.escapeHTML(badge.title))
      expect(miss_queries.size).to eq(1)

      hit_queries = []
      hit_cb = ->(*, payload) { hit_queries << payload[:sql] if payload[:sql].include?('"badge_achievements"') }
      ActiveSupport::Notifications.subscribed(hit_cb, "sql.active_record") do
        get "/#{user.username}"
      end

      expect(response.body).to include(CGI.escapeHTML(badge.title))
      expect(hit_queries).to be_empty
    ensure
      ActionController::Base.perform_caching = original_perform_caching
      ActionController::Base.cache_store = original_cache_store
    end

    it "does not render pins if they don't exist" do
      get "/#{user.username}?i=i" # Pinned will still be present in layout file, but not the "internal" version
      expect(response.body).not_to include "Pinned"
    end

    it "renders profile page of user after changed username and tags redirect with Surrogate-Key" do
      old_username = user.username
      user.update_columns(username: "new_username_yo_#{rand(10_000)}", old_username: old_username,
                          old_old_username: user.old_username)
      get "/#{old_username}"
      expect(response).to redirect_to("/#{user.username}")
      expect(response.headers["Surrogate-Key"]).to eq(user.profile_cache_keys.join(" "))
    end

    it "renders profile page of user after two changed usernames" do
      old_username = user.username
      user.update_columns(username: "new_hotness_#{rand(10_000)}", old_username: old_username,
                          old_old_username: user.old_username)
      user.update_columns(username: "new_new_username_#{rand(10_000)}", old_username: user.username,
                          old_old_username: user.old_username)
      get "/#{old_username}"
      expect(response).to redirect_to("/#{user.username}")
    end

    it "serves the original profile URL and redirects the temporary username after reverting A -> B -> A" do
      original_username = user.username
      temp_username = "#{original_username}_dev"
      Users::Update.call(user, user: { username: temp_username })
      Users::Update.call(user.reload, user: { username: original_username })

      get "/#{temp_username}"
      expect(response).to redirect_to("/#{original_username}")

      get "/#{original_username}"
      expect(response).to have_http_status(:ok)
    end

    it "renders rss feed link if any stories" do
      create(:article, user_id: user.id, with_tags: false)

      get "/#{user.username}"
      expect(response.body).to include("/feed/#{user.username}")
    end

    it "renders sidebar profile field elements in sidebar" do
      create(:profile_field, label: "whoaaaa", display_area: "left_sidebar")
      get "/#{user.username}"
      # Ensure this comes after the start of the sidebar element
      expect(response.body.split("Whoaaaa").first).to include "crayons-layout__sidebar-left"
    end

    context "when user has organization memberships" do
      it "does not list pending invitations as organizations on the profile sidebar" do
        create(:organization_membership, user: user, organization: organization, type_of_user: "pending")
        get "/#{user.username}"
        expect(response.body).not_to include(CGI.escapeHTML(organization.name))
      end

      it "lists accepted organizations on the profile sidebar" do
        create(:organization_membership, user: user, organization: organization, type_of_user: "member")
        get "/#{user.username}"
        expect(response.body).to include(CGI.escapeHTML(organization.name))
      end
    end

    it "does not render special display header elements naively" do
      user.profile.update(location: "hawaii")
      get "/#{user.username}"
      # Does not include the word, but does include the SVG
      expect(response.body).not_to include "<p>Location</p>"
      expect(response.body).to include user.profile.location
      expect(response.body).to include "M18.364 17.364L12 23.728l-6.364-6.364a9 9 0 1112.728 0zM12 13a2 2 0 100-4 2 2 0"
    end

    it "creates profile on the fly if doesn't exist" do
      user.profile.destroy
      expect(user.reload.profile).to be_nil
      get "/#{user.username}"
      expect(user.reload.profile).not_to be_nil
    end

    context "when has comments" do
      before do
        article = create(:article, user: user, with_tags: false)
        create(:comment, user: user, commentable: article, body_markdown: "nice_comment")
        create(:comment, user: user, commentable: article, score: -100, body_markdown: "low_comment")
        create(:comment, user: user, commentable: article, score: -401, body_markdown: "bad_comment")
      end

      it "displays good standing comments", :aggregate_failures do
        sign_in current_user
        get user.path
        expect(response.body).to include("nice_comment")
        expect(response.body).not_to include("low_comment")
        expect(response.body).not_to include("bad_comment")
      end

      it "doesn't display any comments for not signed in user", :aggregate_failures do
        get user.path
        expect(response.body).not_to include("nice_comment")
        expect(response.body).not_to include("bad_comment")
      end
    end

    context "when has articles" do
      before do
        create(:article, user: user, title: "Super Article", published: true)
        create(:article, user: user, score: -500, title: "Spam Article", published: true)
      end

      it "displays articles with good and bad score", :aggregate_failures do
        sign_in current_user
        get user.path
        expect(response.body).to include("Super Article")
        expect(response.body).to include("Spam Article")
      end
    end

    context "when organization" do
      it "renders organization page with noindex and without feed link when org has no articles", :aggregate_failures do
        get organization.path
        expect(response.body).to include(CGI.escapeHTML(organization.name), '<meta name="robots" content="noindex">')
        expect(response.body).not_to include("/feed/#{organization.slug}")
      end

      it "renders organization users on sidebar" do
        create(:organization_membership, user_id: user.id, organization_id: organization.id)
        get organization.path
        expect(response.body).to include user.profile_image_url
      end

      it "renders organization name, email, summary, and location properly encoded", :aggregate_failures do
        organization.update(
          name: "Org & < ' \" 1",
          email: "t&st&mail@example.com",
          summary: "Org & < ' \" &quot; 1",
          location: "123, ave dev & < ' \" &quot; to",
        )
        get organization.path
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.name))
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.email))
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.summary))
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.location))
      end

      it "renders rss feed link if any stories" do
        create(:article, user: user, organization_id: organization.id, with_tags: false)
        get organization.path
        expect(response.body).to include("/feed/#{organization.slug}")
      end

      it "shows noindex when org has articles with negative total score" do
        create(:article, user: user, organization_id: organization.id, score: 2, with_tags: false)
        create(:article, user: user, organization_id: organization.id, score: -4, with_tags: false)
        get organization.path
        expect(response.body).to include("<meta name=\"robots\" content=\"noindex\">")
      end

      it "shows noindex when org has only articles with no score" do
        create(:article, user: user, organization_id: organization.id, score: 0, with_tags: false)
        get organization.path
        expect(response.body).to include("<meta name=\"robots\" content=\"noindex\">")
      end

      it "does not show noindex when org has articles with positive score" do
        create(:article, user: user, organization_id: organization.id, score: 4, with_tags: false)
        get organization.path
        expect(response.body).not_to include("<meta name=\"robots\" content=\"noindex\">")
      end

      it "raises not found if articles have 0 total score and org users have negative total score" do
        user.update_column(:score, -1)
        create(:article, user: user, organization_id: organization.id, score: 0, with_tags: false)
        create(:organization_membership, user_id: user.id, organization_id: organization.id)
        expect { get organization.path }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "does not raise not found if articles have positive total score even if users have negative total score" do
        user.update_column(:score, -1)
        create(:article, user: user, organization_id: organization.id, score: 1, with_tags: false)
        create(:organization_membership, user_id: user.id, organization_id: organization.id)
        get organization.path
        expect(response).to be_successful
      end

      it "does not raise not found if user signed in" do
        sign_in current_user
        user.update_column(:score, -1)
        create(:article, user: user, organization_id: organization.id, score: 0, with_tags: false)
        create(:organization_membership, user_id: user.id, organization_id: organization.id)
        get organization.path
        expect(response).to be_successful
      end

      # rubocop:disable RSpec/NestedGroups
      context "when redirecting inactive organization in subforem" do
        let!(:default_subforem) { create(:subforem, domain: "www.example.com") }
        let!(:other_subforem)   { create(:subforem, domain: "other.com") }

        context "when the organization is 'inactive' in the current subforem" do
          before do
            organization.articles.delete_all
          end

          after do
            RequestStore.store[:default_subforem_id] = nil
            RequestStore.store[:subforem_id] = nil
          end

          it "redirects to the organization's path in the default subforem" do
            get organization.path, headers: { "Host" => other_subforem.domain }
            expect(response).to have_http_status(:moved_permanently)
            expect(response).to redirect_to(
              URL.url(organization.slug, default_subforem),
            )
          end
        end

        context "when the organization has stories in the current subforem" do
          before do
            # Give the organization a story so it is 'active' in other_subforem
            create(:article, organization: organization, subforem: other_subforem)

            RequestStore.store[:default_subforem_id] = default_subforem.id
            RequestStore.store[:subforem_id] = other_subforem.id
          end

          after do
            RequestStore.store[:default_subforem_id] = nil
            RequestStore.store[:subforem_id] = nil
          end

          it "does not redirect away from the current subforem" do
            get organization.path, headers: { "Host" => other_subforem.domain }
            expect(response).to have_http_status(:ok)
            expect(response).not_to be_redirect
          end
        end

        context "when the organization only has stories in the default subforem" do
          before do
            # Org is empty in 'other_subforem', but has a story in default_subforem
            create(:article, organization: organization, subforem: default_subforem)

            RequestStore.store[:default_subforem_id] = default_subforem.id
            RequestStore.store[:subforem_id] = other_subforem.id
          end

          after do
            RequestStore.store[:default_subforem_id] = nil
            RequestStore.store[:subforem_id] = nil
          end

          it "redirects to the default subforem since it's 'inactive' in current subforem" do
            get organization.path, headers: { "Host" => other_subforem.domain }
            expect(response).to have_http_status(:moved_permanently)
            expect(response).to redirect_to(
              URL.url(organization.slug, default_subforem),
            )
          end
        end
      end
      # rubocop:enable RSpec/NestedGroups
    end

    context "when displaying a GitHub repository on the profile" do
      let(:github_user) { create(:user, :with_identity, identities: %i[github], profile_image: nil) }
      let(:params) do
        {
          description: "A book bot :robot:",
          featured: true,
          github_id_code: generate(:github_id_code),
          name: Faker::Book.title,
          stargazers_count: 1,
          url: Faker::Internet.url
        }
      end

      before do
        omniauth_mock_github_payload
      end

      it "renders emoji in description of featured repository" do
        GithubRepo.upsert(github_user, **params)

        get "/#{github_user.username}"
        expect(response.body).to include("A book bot 🤖")
      end

      it "does not show a non featured repository" do
        GithubRepo.upsert(github_user, **params.merge(featured: false))

        get "/#{github_user.username}"
        expect(response.body).not_to include("A book bot 🤖")
      end

      it "does not render anything if the user has not authenticated through GitHub" do
        get "/#{github_user.username}"
        expect(response.body).not_to include("github-repos-container")
      end
    end

    # rubocop:disable RSpec/NestedGroups
    describe "not found and no index behaviour" do
      let(:spam_user) { create(:user, :spam, profile_image: nil) }
      let(:admin_user) { create(:user, :admin, :without_profile, profile_image: nil) }

      it "raises not found for banished users" do
        banishable_user = create(:user, profile_image: nil)
        Moderator::BanishUser.call(admin: user, user: banishable_user)
        expect { get "/#{banishable_user.reload.old_username}" }.to raise_error(ActiveRecord::RecordNotFound)
        expect { get "/#{banishable_user.reload.username}" }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "raises not found for spammers with articles for signed out and signed in users", :aggregate_failures do
        create(:article, user: spam_user, with_tags: false)
        expect { get spam_user.path }.to raise_error(ActiveRecord::RecordNotFound)

        sign_in current_user
        expect { get spam_user.path }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "renders spammer users for admins", :aggregate_failures do
        sign_in admin_user
        get spam_user.path
        expect(response).to be_successful
        expect(response.body).to include("Spam")
      end

      context "when a user is signed in" do
        it "does not raise not found for suspended users who have no current content" do
          sign_in current_user

          suspended_user = create(:user)
          suspended_user.add_role(:suspended)
          create(:article, user_id: user.id, published: false, published_at: Date.tomorrow)

          get "/#{suspended_user.username}"
          expect(response).to be_successful
        end
      end

      context "when a user is not signed in" do
        it "raises not found for suspended users who do not have published content" do
          suspended_user = create(:user)
          suspended_user.add_role(:suspended)
          create(:article, user_id: user.id, published: false, published_at: Date.tomorrow)

          expect { get "/#{suspended_user.username}" }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      it "renders noindex meta if suspended (and has published content)" do
        user.add_role(:suspended)

        create(:article, user_id: user.id)
        get "/#{user.username}"
        expect(response.body).to include("<meta name=\"robots\" content=\"noindex\">")
      end

      it "raises not found if user not registered" do
        user.update_column(:registered, false)
        expect { get "/#{user.username}" }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
    # rubocop:enable RSpec/NestedGroups
  end

  describe "redirect to moderation" do
    it "redirects user /admin and /moderate to admin user page", :aggregate_failures do
      get "/#{user.username}/admin"
      expect(response).to redirect_to admin_user_path(user.id)

      get "/#{user.username}/moderate"
      expect(response).to redirect_to admin_user_path(user.id)
    end

    it "redirects organization /moderate and /admin to admin organization page", :aggregate_failures do
      get "/#{organization.slug}/moderate"
      expect(response).to redirect_to admin_organization_path(organization.id)

      get "/#{organization.slug}/admin"
      expect(response).to redirect_to admin_organization_path(organization.id)
    end
  end
end
