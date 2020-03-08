require "rails_helper"

RSpec.describe "UserProfiles", type: :request do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  describe "GET /user" do
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

    it "does not render pins if they don't exist" do
      get "/#{user.username}"
      expect(response.body).not_to include "Pinned"
    end

    it "renders profile page of user after changed username" do
      old_username = user.username
      user.update(username: "new_username_yo_#{rand(10_000)}")
      get "/#{old_username}"
      expect(response).to redirect_to("/#{user.username}")
    end

    it "renders profile page of user after two changed usernames" do
      old_username = user.username
      user.update(username: "new_hotness_#{rand(10_000)}")
      user.update(username: "new_new_username_#{rand(10_000)}")
      get "/#{old_username}"
      expect(response).to redirect_to("/#{user.username}")
    end

    it "raises not found for banished users" do
      banishable_user = create(:user)
      Moderator::BanishUser.call(admin: user, user: banishable_user)
      expect { get "/#{banishable_user.reload.old_username}" }.to raise_error(ActiveRecord::RecordNotFound)
      expect { get "/#{banishable_user.reload.username}" }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "renders noindex meta if banned" do
      user.add_role(:banned)
      get "/#{user.username}"
      expect(response.body).to include("<meta name=\"googlebot\" content=\"noindex\">")
    end

    it "does not render noindex meta if not banned" do
      get "/#{user.username}"
      expect(response.body).not_to include("<meta name=\"googlebot\" content=\"noindex\">")
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

      it "renders no sponsors if not sponsor" do
        get organization.path
        expect(response.body).not_to include "Gold Community Sponsor"
      end

      it "renders sponsor if it is sponsored" do
        create(:sponsorship, level: :gold, status: :live, organization: organization)
        get organization.path
        expect(response.body).to include "Gold Community Sponsor"
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
    end

    context "when github repo" do
      before do
        repo = build(:github_repo, user: user)
        params = { name: Faker::Book.title, user_id: user.id, github_id_code: repo.github_id_code,
                   url: Faker::Internet.url, description: "A book bot :robot:", featured: true,
                   stargazers_count: 1 }
        updated_repo = GithubRepo.find_or_create(params)

        user.github_repos = [updated_repo]
      end

      it "renders emoji in description of pinned github repo" do
        get "/#{user.username}"
        expect(response.body).to include "A book bot 🤖"
      end
    end
  end

  describe "redirect to moderation" do
    it "redirects to admin" do
      user = create(:user)
      get "/#{user.username}/admin"
      expect(response.body).to redirect_to "/admin/users/#{user.id}/edit"
    end

    it "redirects to moderate" do
      user = create(:user)
      get "/#{user.username}/moderate"
      expect(response.body).to redirect_to "/internal/users/#{user.id}"
    end
  end
end
