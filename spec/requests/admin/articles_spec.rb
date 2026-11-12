require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/content_manager/articles" do
  let(:super_admin) { create(:user, :super_admin, :without_profile, profile_image: nil) }
  let(:article) { create(:article, user: super_admin, with_tags: false, with_main_image: false) }

  it_behaves_like "an InternalPolicy dependant request", Article do
    let(:request) { get admin_articles_path }
  end

  describe "GET /admin/content_manager/articles" do
    before { sign_in super_admin }

    it "browses hot, chronological, and top-3 pages without counting articles", :aggregate_failures do
      base_attributes = article.attributes.except("id", "tag_list")
      Article.insert_all!(
        Array.new(50) do |index|
          slug = "admin-page-post-#{index}"
          base_attributes.merge(
            "title" => "Admin Page Post #{index}",
            "slug" => slug,
            "path" => "/#{super_admin.username}/#{slug}",
          )
        end,
      )
      count_queries = []
      subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
        count_queries << payload[:sql] if payload[:sql].match?(/SELECT COUNT\(.*FROM "articles"/i)
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        { nil => 30, "chronological" => 50, "top-3" => 50 }.each do |state, page_size|
          get admin_articles_path, params: { state: state }
          first_page = Nokogiri::HTML(response.body)
          expect(response).to have_http_status(:ok)
          expect(first_page.css(".js-individual-article").size).to eq(page_size)
          expect(first_page.css('a[rel="prev"]')).to be_empty
          next_link = first_page.at_css('a[rel="next"]')
          expect(next_link).to be_present

          get next_link["href"]
          last_page = Nokogiri::HTML(response.body)
          expect(response).to have_http_status(:ok)
          expect(request.params["state"]).to eq(state)
          expect(last_page.css(".js-individual-article").size).to eq(51 - page_size)
          expect(last_page.css('a[rel="prev"]')).to be_present
          expect(last_page.css('a[rel="next"]')).to be_empty

          get admin_articles_path, params: { state: state, page: 3 }
          empty_page = Nokogiri::HTML(response.body)
          expect(response).to have_http_status(:ok)
          expect(empty_page.css(".js-individual-article")).to be_empty
          expect(empty_page.at_css('a[rel="prev"]')&.[]("href")).to eq(admin_articles_path(state: state, page: 2))
          expect(empty_page.css('a[rel="next"]')).to be_empty
        end
      end

      expect(count_queries.size).to eq(0)
    end

    it "batches reaction counts and preloads associations without per-article N+1 queries", :aggregate_failures do
      note_author = create(:user, :without_profile, profile_image: nil, username: "mod_note_author")
      trusted_user = create(:user, :trusted, :without_profile, profile_image: nil)
      articles = Array.new(3) do
        author = create(:user, :warned, :without_profile, profile_image: nil)
        Note.create!(noteable: author, author: note_author, content: "Moderator note on author", reason: "warned")
        post_record = create(:article, user: author, with_tags: false, with_main_image: false)
        create(:reaction, reactable: post_record, user: trusted_user, category: "vomit", status: "valid")
        create(:reaction, reactable: post_record, user: trusted_user, category: "thumbsup")
        post_record
      end

      queries = []
      subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
        next if payload[:name] == "SCHEMA"

        queries << payload[:sql]
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        get admin_articles_path
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Moderator note on author", "mod_note_author")
      expect(articles.size).to eq(3)

      reaction_queries = queries.select { |sql| sql.include?('FROM "reactions"') }
      note_queries = queries.select { |sql| sql.include?('FROM "notes"') }
      context_note_queries = queries.select { |sql| sql.include?('FROM "context_notes"') }
      warned_role_count_queries = queries.select { |sql| sql.include?('FROM "roles"') && sql.include?("COUNT(*)") }

      expect(reaction_queries.size).to eq(1)
      expect(note_queries.size).to eq(1)
      expect(context_note_queries.size).to eq(1)
      expect(warned_role_count_queries).to be_empty
    end
  end

  describe "GET /admin/content_manager/articles/:id" do
    before { sign_in super_admin }

    it "preloads privileged reactions and author notes without hydrating public reaction users", :aggregate_failures do
      author = create(:user, :warned, :without_profile, profile_image: nil)
      note_author = create(:user, :without_profile, profile_image: nil, username: "show_note_author")
      Note.create!(noteable: author, author: note_author, content: "Show page author note", reason: "note")
      target_article = create(:article, user: author, with_tags: false, with_main_image: false)
      flagger = create(:user, :trusted, :without_profile, profile_image: nil, name: "Trusted Flagger")
      public_liker = create(:user, :without_profile, profile_image: nil, name: "Public Liker")
      create(:reaction, reactable: target_article, user: flagger, category: "vomit", status: "valid")
      create(:reaction, reactable: target_article, user: public_liker, category: "like")

      queries = []
      subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
        next if payload[:name] == "SCHEMA"

        queries << payload[:sql]
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        get admin_article_path(target_article.id)
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Trusted Flagger", "Show page author note", "show_note_author")
      expect(response.body).not_to include("Public Liker")

      reaction_queries = queries.select { |sql| sql.include?('FROM "reactions"') }
      note_queries = queries.select { |sql| sql.include?('FROM "notes"') }

      expect(reaction_queries.size).to eq(1)
      expect(reaction_queries.first).to include('"reactions"."category" IN')
      expect(note_queries.size).to eq(1)
    end
  end

  context "when updating an article via /admin/content_manager/articles" do
    before do
      sign_in super_admin
    end

    it "allows an Admin to add a co-author or multiple co-authors to an individual article", :aggregate_failures do
      expect do
        article.update_columns(co_author_ids: [1])
      end.to change(article, :co_author_ids).from([]).to([1])

      article.update_columns(co_author_ids: [2, 3])
      expect(article.co_author_ids).to eq([2, 3])
    end

    it "allows an Admin to update the author" do
      allow(NotificationSubscriptions::UpdateWorker).to receive(:perform_async)
      new_author = create(:user, :without_profile, profile_image: nil)

      patch admin_article_path(article.id), params: { article: { user_id: new_author.id } }
      expect(article.reload.user_id).to eq(new_author.id)
      expect(NotificationSubscriptions::UpdateWorker).to have_received(:perform_async)
    end

    it "allows an Admin to mark an article as approved and creates an audit log on update", :aggregate_failures do
      Audit::Subscribe.listen(:moderator)

      expect do
        patch admin_article_path(article.id), params: { article: { approved: true } }
      end.to change { article.reload.approved }.to(true)
        .and change(AuditLog, :count).by(1)
    ensure
      Audit::Subscribe.forget(:moderator)
    end

    it "allows an Admin to mark an article as featured" do
      expect do
        patch admin_article_path(article.id), params: { article: { featured: true } }
      end.to change { article.reload.featured }.to(true)
    end

    it "allows an Admin to mark an article as pinned" do
      decorated_article = article.decorate

      expect do
        post pin_admin_article_path(article.id)
      end.to change { decorated_article.pinned? }.to(true)
    end

    it "allows an Admin to update the published at datetime for an article" do
      updated_published_at = article.published_at - 5.hours
      expect do
        patch admin_article_path(article.id), params: { article: {
          "published_at(1i)": updated_published_at.year,
          "published_at(2i)": updated_published_at.month,
          "published_at(3i)": updated_published_at.day,
          "published_at(4i)": updated_published_at.hour,
          "published_at(5i)": updated_published_at.min,
          "published_at(6i)": updated_published_at.sec
        } }
      end.to change { article.reload.published_at }.to(DateTime.parse(updated_published_at.to_s))
    end

    it "allows an Admin to update an article's context_notes" do
      context_note = create(:context_note, article: article,
                                           body_markdown: "Original markdown note that is long enough")

      expect do
        patch admin_article_path(article.id), params: { article: { context_notes_attributes: {
          "0" => { id: context_note.id, body_markdown: "Updated markdown note that is long enough" }
        } } }
      end.to change { context_note.reload.body_markdown }.to("Updated markdown note that is long enough")
    end
  end

  context "when unpinning an article" do
    before do
      sign_in super_admin
    end

    it "responds with :not_found with an invalid article id" do
      expect { delete unpin_admin_article_path(9999) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "allows an admin to unpin an article and creates an audit log", :aggregate_failures do
      Audit::Subscribe.listen(:moderator)
      PinnedArticle.set(article)

      expect do
        delete unpin_admin_article_path(article.id)
      end.to change(AuditLog, :count).by(1)

      expect(PinnedArticle.exists?).to be(false)
      expect(response).to redirect_to(admin_article_path(article.id))
    ensure
      Audit::Subscribe.forget(:moderator)
    end

    it "allows an admin to unpin an article via Ajax", :aggregate_failures do
      PinnedArticle.set(article)

      delete unpin_admin_article_path(article.id), xhr: true

      expect(PinnedArticle.exists?).to be(false)
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
      expect(response.body).to include('data-controller="article"')
    end
  end
end
