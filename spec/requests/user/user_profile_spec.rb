require "rails_helper"

RSpec.describe "UserProfiles" do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:current_user) { create(:user) }

  describe "GET /:username" do
    it "renders to appropriate page" do
      get "/#{user.username}"
      expect(response.body).to include CGI.escapeHTML(user.name)
    end

    it "renders pins if any" do
      create(:article, user_id: user.id)
      create(:article, user_id: user.id)
      last_article = create(:article, user_id: user.id)
      create(:profile_pin, pinnable: last_article, profile: user)
      get "/#{user.username}"
      expect(response.body).to include "Pinned"
    end

    it "calls user by their username in the 'more info' area" do
      get "/#{user.username}"
      expect(response.body).to include "More info about @#{user.username}"
    end

    it "does not render pins if they don't exist" do
      get "/#{user.username}?i=i" # Pinned will still be present in layout file, but not the "internal" version
      expect(response.body).not_to include "Pinned"
    end

    it "renders profile page of user after changed username" do
      old_username = user.username
      user.update_columns(username: "new_username_yo_#{rand(10_000)}", old_username: old_username,
                          old_old_username: user.old_username)
      get "/#{old_username}"
      expect(response).to redirect_to("/#{user.username}")
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

    it "does not render noindex meta if not suspended" do
      get "/#{user.username}"
      expect(response.body).not_to include("<meta name=\"robots\" content=\"noindex\">")
    end

    it "renders rss feed link if any stories" do
      create(:article, user_id: user.id)

      get "/#{user.username}"
      expect(response.body).to include("/feed/#{user.username}")
    end

    it "does not render feed link if no stories" do
      get "/#{user.username}"
      expect(response.body).not_to include("/feed/#{user.username}")
    end

    it "renders sidebar profile field elements in sidebar" do
      create(:profile_field, label: "whoaaaa", display_area: "left_sidebar")
      get "/#{user.username}"
      # Ensure this comes after the start of the sidebar element
      expect(response.body.split("Whoaaaa").first).to include "crayons-layout__sidebar-left"
    end

    it "does not render special display header elements naively" do
      user.profile.update(location: "hawaii")
      get "/#{user.username}"
      # Does not include the word, but does include the SVG
      expect(response.body).not_to include "<p>Location</p>"
      expect(response.body).to include user.profile.location
      expect(response.body).to include "M18.364 17.364L12 23.728l-6.364-6.364a9 9 0 1112.728 0zM12 13a2 2 0 100-4 2 2 0"
    end

    context "when has comments" do
      before do
        create(:comment, user: user, body_markdown: "nice_comment")
        create(:comment, user: user, score: -100, body_markdown: "low_comment")
        create(:comment, user: user, score: -401, body_markdown: "bad_comment")
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
      it "renders organization page if org" do
        get organization.path
        expect(response.body).to include CGI.escapeHTML(organization.name)
      end

      it "renders organization users on sidebar" do
        create(:organization_membership, user_id: user.id, organization_id: organization.id)
        get organization.path
        expect(response.body).to include user.profile_image_url
      end

      it "renders organization name properly encoded" do
        organization.update(name: "Org & < ' \" 1")
        get organization.path
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.name))
      end

      it "renders organization email properly encoded" do
        organization.update(email: "t&st&mail@dev.to")
        get organization.path
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.email))
      end

      it "renders organization summary properly encoded" do
        organization.update(summary: "Org & < ' \" &quot; 1")
        get organization.path
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.summary))
      end

      it "renders organization location properly encoded" do
        organization.update(location: "123, ave dev & < ' \" &quot; to")
        get organization.path
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.location))
      end

      it "renders rss feed link if any stories" do
        create(:article, organization_id: organization.id)
        get organization.path
        expect(response.body).to include("/feed/#{organization.slug}")
      end

      it "does not render feed link if no stories" do
        get organization.path
        expect(response.body).not_to include("/feed/#{organization.slug}")
      end

      it "shows noindex when org has no articles" do
        get organization.path
        expect(response.body).to include("<meta name=\"robots\" content=\"noindex\">")
      end

      it "shows noindex when org has articles with negative total score" do
        create(:article, organization_id: organization.id, score: 2)
        create(:article, organization_id: organization.id, score: -4)
        get organization.path
        expect(response.body).to include("<meta name=\"robots\" content=\"noindex\">")
      end

      it "shows noindex when org has only articles with no score" do
        create(:article, organization_id: organization.id, score: 0)
        get organization.path
        expect(response.body).to include("<meta name=\"robots\" content=\"noindex\">")
      end

      it "does not show noindex when org has articles with positive score" do
        create(:article, organization_id: organization.id, score: 4)
        get organization.path
        expect(response.body).not_to include("<meta name=\"robots\" content=\"noindex\">")
      end

      it "raises not found if articles have 0 total score and org users have negative total score" do
        user.update_column(:score, -1)
        create(:article, organization_id: organization.id, score: 0)
        create(:organization_membership, user_id: user.id, organization_id: organization.id)
        expect { get organization.path }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "does not raise not found if articles have positive total score even if users have negative total score" do
        user.update_column(:score, -1)
        create(:article, organization_id: organization.id, score: 1)
        create(:organization_membership, user_id: user.id, organization_id: organization.id)
        get organization.path
        expect(response).to be_successful
      end

      it "does not raise not found if user signed in" do
        sign_in current_user
        user.update_column(:score, -1)
        create(:article, organization_id: organization.id, score: 0)
        create(:organization_membership, user_id: user.id, organization_id: organization.id)
        get organization.path
        expect(response).to be_successful
      end
    end

    context "when displaying a GitHub repository on the profile" do
      let(:github_user) { create(:user, :with_identity, identities: %i[github]) }
      let(:params) do
        {
          description: "A book bot :robot:",
          featured: true,
          github_id_code: build(:github_repo).github_id_code,
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
      let(:spam_user) { create(:user, :spam) }
      let(:admin_user) { create(:user, :admin) }

      it "raises not found for banished users" do
        banishable_user = create(:user)
        Moderator::BanishUser.call(admin: user, user: banishable_user)
        expect { get "/#{banishable_user.reload.old_username}" }.to raise_error(ActiveRecord::RecordNotFound)
        expect { get "/#{banishable_user.reload.username}" }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "raises not found for spammers with articles for signed in" do
        sign_in current_user
        create(:article, user: spam_user)
        expect { get spam_user.path }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "raises not found for spammers with articles for signed out" do
        create(:article, user: spam_user)
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
    it "redirects to admin" do
      user = create(:user)
      get "/#{user.username}/admin"
      expect(response.body).to redirect_to admin_user_path(user.id)
    end

    it "redirects to moderate" do
      user = create(:user)
      get "/#{user.username}/moderate"
      expect(response.body).to redirect_to admin_user_path(user.id)
    end
  end
end
