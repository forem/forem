require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/content_manager/comments" do
  let(:super_admin) { create(:user, :super_admin) }
  let(:article) { create(:article, user: super_admin, with_tags: false, with_main_image: false) }

  it_behaves_like "an InternalPolicy dependant request", Comment do
    let(:request) { get admin_comments_path }
  end

  describe "GET /admin/content_manager/comments" do
    before { sign_in super_admin }

    [nil, "toplast-30"].each do |state|
      it "browses #{state || 'default'} pages without counting comments", :aggregate_failures do
        page_size = 50
        create_list(:comment, page_size + 1, commentable: article, user: super_admin)
        count_queries = []
        subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
          count_queries << payload[:sql] if payload[:sql].match?(/SELECT COUNT\(.*FROM "comments"/i)
        end

        ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
          get admin_comments_path, params: { state: state }
          first_page = Nokogiri::HTML(response.body)
          expect(response).to have_http_status(:ok)
          expect(first_page.css("article.crayons-card").size).to eq(page_size)
          expect(first_page.css('a[rel="prev"]')).to be_empty
          next_link = first_page.at_css('a[rel="next"]')
          expect(next_link).to be_present

          get next_link["href"]
          last_page = Nokogiri::HTML(response.body)
          expect(response).to have_http_status(:ok)
          expect(request.params["state"]).to eq(state)
          expect(last_page.css("article.crayons-card").size).to eq(1)
          expect(last_page.css('a[rel="prev"]')).to be_present
          expect(last_page.css('a[rel="next"]')).to be_empty

          get admin_comments_path, params: { state: state, page: 3 }
          empty_page = Nokogiri::HTML(response.body)
          expect(response).to have_http_status(:ok)
          expect(empty_page.css("article.crayons-card")).to be_empty
          expect(empty_page.at_css('a[rel="prev"]')&.[]("href")).to eq(admin_comments_path(state: state, page: 2))
          expect(empty_page.css('a[rel="next"]')).to be_empty
        end

        expect(count_queries).to be_empty
      end
    end

    it "batches privileged reaction counts and preloads favorited_by_user without N+1 queries", :aggregate_failures do
      trusted_user = create(:user, :trusted)
      favoriter = create(:user, username: "comment_favoriter")
      comments = Array.new(3) do
        comment_record = create(:comment, commentable: article, user: super_admin, favorited_by_user: favoriter)
        create(:reaction, reactable: comment_record, user: trusted_user, category: "vomit", status: "valid")
        create(:reaction, reactable: comment_record, user: trusted_user, category: "thumbsup")
        create(:reaction, reactable: comment_record, user: trusted_user, category: "thumbsdown")
        create(:reaction, reactable: comment_record, user: trusted_user, category: "like")
        comment_record
      end

      queries = []
      subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
        next if payload[:name] == "SCHEMA"

        queries << payload[:sql]
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        get admin_comments_path
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("comment_favoriter")
      expect(comments.size).to eq(3)

      cards = Nokogiri::HTML(response.body).css("article.crayons-card")
      title = I18n.t("views.moderations.actions.thumb_down")
      comments.each do |comment|
        card = cards.detect { |element| element.at_css(%(a[href="#{admin_comment_path(comment.id)}"])) }
        count = card&.at_css(%(span[title="#{title}"] > span))
        expect(count&.text&.strip).to eq("1")
      end

      reaction_queries = queries.select { |sql| sql.include?('FROM "reactions"') }
      expect(reaction_queries.size).to eq(1)
    end
  end

  describe "GET /admin/content_manager/comments/:id" do
    before { sign_in super_admin }

    it "preloads privileged reactions and their users in a single reaction query", :aggregate_failures do
      target_comment = create(:comment, commentable: article, user: super_admin)
      flagger = create(:user, :trusted, name: "Trusted Comment Flagger")
      quality_reactor = create(:user, :trusted, name: "Trusted Quality Reactor")
      public_liker = create(:user, name: "Public Comment Liker")
      create(:reaction, reactable: target_comment, user: flagger, category: "vomit", status: "valid")
      create(:reaction, reactable: target_comment, user: quality_reactor, category: "thumbsup")
      create(:reaction, reactable: target_comment, user: public_liker, category: "like")

      queries = []
      subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
        next if payload[:name] == "SCHEMA"

        queries << payload[:sql]
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        get admin_comment_path(target_comment.id)
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Trusted Comment Flagger")
      expect(response.body).not_to include("Public Comment Liker")

      reaction_queries = queries.select { |sql| sql.include?('FROM "reactions"') }
      expect(reaction_queries.size).to eq(1)
      expect(reaction_queries.first).to include('"reactions"."category" IN')

      get admin_comment_path(target_comment.id), params: { tab: "quality_reactions" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Trusted Quality Reactor")
    end
  end

  describe "support admin access" do
    let(:comment) { create(:comment, commentable: create(:article)) }

    context "when the user is a support admin" do
      before { sign_in create(:user, :support_admin) }

      it "allows access to the comments index" do
        get admin_comments_path
        expect(response).to have_http_status(:success)
      end

      it "allows access to an individual comment" do
        get admin_comment_path(comment.id)
        expect(response).to have_http_status(:success)
      end

      it "does not allow unfavoriting a comment" do
        expect do
          delete unfavorite_admin_comment_path(comment.id)
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when the user has no admin role", :proper_status do
      before { sign_in create(:user) }

      it "does not allow access to an individual comment" do
        get admin_comment_path(comment.id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
