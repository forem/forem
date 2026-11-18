require "rails_helper"

RSpec.describe "Api::V1::OrganizationArticleReactions" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:api_secret) { create(:api_secret, user: user) }
  let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json", "api-key" => api_secret.secret } }
  let(:path) { "/api/organizations/#{organization.id}/article_reactions" }
  let(:article) { create(:article, organization: organization) }

  before { FeatureFlag.enable(:org_article_reactions, FeatureFlag::Actor[organization]) }

  context "when authorizing" do
    it "allows admins of an enabled organization" do
      create(:organization_membership, organization: organization, user: user, type_of_user: "admin")
      get path, headers: headers
      expect(response).to have_http_status(:ok)
    end

    it "allows super admins of an enabled organization" do
      user.add_role(:super_admin)
      get path, headers: headers
      expect(response).to have_http_status(:ok)
    end

    it "rejects unauthenticated requests" do
      get path, headers: headers.except("api-key")
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects members, pending members, guests, and outsiders" do
      get path, headers: headers
      expect(response).to have_http_status(:unauthorized)
      membership = create(:organization_membership, organization: organization, user: user)
      %w[member pending guest].each do |role|
        membership.update!(type_of_user: role)
        get path, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it "rejects admins and super admins when the organization is not enabled" do
      create(:organization_membership, organization: organization, user: user, type_of_user: "admin")
      FeatureFlag.disable(:org_article_reactions, FeatureFlag::Actor[organization])
      FeatureFlag.enable(:org_article_reactions, FeatureFlag::Actor[create(:organization)])
      get path, headers: headers
      expect(response).to have_http_status(:unauthorized)
      user.add_role(:super_admin)
      get path, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 when the organization does not exist" do
      user.add_role(:super_admin)
      get "/api/organizations/0/article_reactions", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the caller is an organization admin" do
    before { create(:organization_membership, organization: organization, user: user, type_of_user: "admin") }

    it "returns public reactions on published organization articles with public user fields", :aggregate_failures do
      reactor = create(:user, github_username: "reactor-gh", twitter_username: "reactor_tw")
      reaction = create(:reaction, reactable: article, user: reactor, category: "unicorn")

      get path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([{
                                           "article_id" => article.id,
                                           "category" => "unicorn",
                                           "created_at" => reaction.created_at.as_json,
                                           "user" => {
                                             "user_id" => reactor.id,
                                             "username" => reactor.username,
                                             "name" => reactor.name,
                                             "github_username" => "reactor-gh",
                                             "twitter_username" => "reactor_tw"
                                           }
                                         }])
      expect(response.parsed_body.first["user"].keys).not_to include("email")
      expect(response.headers["Cache-Control"]).to eq("private, no-store")
      expect(response.headers["Surrogate-Control"]).to eq("no-store")
    end

    it "excludes reading list saves and privileged reactions" do
      like = create(:reaction, reactable: article)
      create(:reading_reaction, reactable: article)
      trusted = create(:user, :trusted)
      create(:reaction, reactable: article, user: trusted, category: "thumbsup")
      create(:thumbsdown_reaction, reactable: article, user: trusted)
      create(:vomit_reaction, reactable: article, user: trusted)

      get path, headers: headers

      expect(response.parsed_body.map { |r| [r["article_id"], r["category"], r["user"]["user_id"]] })
        .to eq([[article.id, "like", like.user_id]])
    end

    it "excludes other organizations' articles, unpublished articles, other subforems, and comments" do
      create(:subforem, domain: "forem.test")
      reaction = create(:reaction, reactable: article)
      create(:reaction, reactable: create(:article, organization: create(:organization)))
      unpublished = create(:article, organization: organization)
      create(:reaction, reactable: unpublished)
      unpublished.update_columns(published: false)
      create(:reaction, reactable: create(:article, organization: organization, subforem: create(:subforem)))
      create(:reaction, reactable: create(:comment, commentable: article))

      get path, headers: headers

      expect(response.parsed_body.map { |r| r["user"]["user_id"] }).to eq([reaction.user_id])
    end

    it "drops reactions that were removed or whose user was deleted" do
      kept = create(:reaction, reactable: article)
      create(:reaction, reactable: article).destroy!
      create(:reaction, reactable: article).user.destroy!

      get path, headers: headers

      expect(response.parsed_body.map { |r| r["user"]["user_id"] }).to eq([kept.user_id])
    end

    it "skips reactions whose user is deleted after the reactions are loaded" do
      kept = create(:reaction, reactable: article)
      orphaned = create(:reaction, reactable: article)
      deleted = false
      delete_user = lambda do |*, payload|
        next if deleted || payload[:sql].exclude?('ORDER BY "reactions"."created_at" DESC')

        deleted = true
        orphaned.user.destroy!
      end

      ActiveSupport::Notifications.subscribed(delete_user, "sql.active_record") { get path, headers: headers }

      expect(deleted).to be(true)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |r| r["user"]["user_id"] }).to eq([kept.user_id])
    end

    it "filters by article_id and returns nothing for articles outside the organization" do
      other_article = create(:article, organization: organization)
      create(:reaction, reactable: article)
      wanted = create(:reaction, reactable: other_article)
      outside = create(:article)
      create(:reaction, reactable: outside)

      get path, params: { article_id: other_article.id }, headers: headers
      expect(response.parsed_body.map { |r| r["user"]["user_id"] }).to eq([wanted.user_id])

      get path, params: { article_id: outside.id }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])

      ["", "0", "abc", "#{other_article.id}abc", "-1", "1.5"].each do |article_id|
        get path, params: { article_id: article_id }, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it "filters by since and rejects invalid timestamps" do
      old = create(:reaction, reactable: article)
      old.update_columns(created_at: 3.days.ago)
      recent = create(:reaction, reactable: article)

      get path, params: { since: 1.day.ago.iso8601 }, headers: headers
      expect(response.parsed_body.map { |r| r["user"]["user_id"] }).to eq([recent.user_id])

      ["", " ", "yesterday", "2026-01-01", "2026-01-01T00:00:00", "2026-01-01T00:00:00+00:99",
       "2026-01-01T00:00:00+25:00", "2026-13-45T00:00:00Z", "2026-02-30T00:00:00Z", "2026-02-31"].each do |since|
        get path, params: { since: since }, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.headers["Cache-Control"]).to eq("private, no-store")
      end
    end

    it "applies the offset of a non-UTC since timestamp" do
      cutoff = 1.day.ago.change(usec: 0)
      before_cutoff = create(:reaction, reactable: article)
      before_cutoff.update_columns(created_at: cutoff - 1.hour)
      after_cutoff = create(:reaction, reactable: article)
      after_cutoff.update_columns(created_at: cutoff + 1.hour)

      get path, params: { since: cutoff.in_time_zone("Asia/Kolkata").iso8601 }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |r| r["user"]["user_id"] }).to eq([after_cutoff.user_id])
    end

    it "ignores non-scalar page, per_page, and article_id values" do
      other_article = create(:article, organization: organization)
      create(:reaction, reactable: article)
      create(:reaction, reactable: other_article)

      queries = ["page[]=2", "per_page[]=1", "article_id[]=#{other_article.id}", "article_id[x]=#{other_article.id}"]
      queries.each do |query|
        get "#{path}?#{query}", headers: headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.size).to eq(2)
      end
    end

    it "orders newest first with id as a tie breaker and paginates" do
      first, second, third = create_list(:reaction, 3, reactable: article)
      first.update_columns(created_at: 2.days.ago)
      second.update_columns(created_at: 1.day.ago)
      third.update_columns(created_at: second.created_at)

      get path, params: { per_page: 2 }, headers: headers
      expect(response.parsed_body.map { |r| r["user"]["user_id"] }).to eq([third.user_id, second.user_id])

      get path, params: { per_page: 2, page: 2 }, headers: headers
      expect(response.parsed_body.map { |r| r["user"]["user_id"] }).to eq([first.user_id])
    end

    it "supports session authentication" do
      create(:reaction, reactable: article)
      sign_in user

      get path, headers: headers.except("api-key")

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(1)
    end
  end
end
