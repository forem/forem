require "rails_helper"

RSpec.shared_examples "an elevated privilege required request" do |path|
  context "when not logged-in" do
    it "does not grant access", proper_status: true do
      get path
      expect(response).to have_http_status(:not_found)
    end

    it "raises Pundit::NotAuthorizedError internally" do
      expect { get path }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when user is not trusted" do
    before { sign_in create(:user) }

    it "does not grant access", proper_status: true do
      get path
      expect(response).to have_http_status(:not_found)
    end

    it "internally raise Pundit::NotAuthorized internally" do
      expect { get path }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end

RSpec.describe "Moderations", type: :request do
  let(:trusted_user) { create(:user, :trusted) }
  let(:article) { create(:article) }
  let(:comment) { create(:comment, commentable: article) }
  let(:staff_account) { create(:user) }

  it_behaves_like "an elevated privilege required request", "/username/random-article/mod"
  it_behaves_like "an elevated privilege required request", "/username/comment/1/mod"
  it_behaves_like "an elevated privilege required request", "/username/random-article/actions_panel"

  context "when user is trusted" do
    before do
      sign_in trusted_user
      allow(User).to receive(:staff_account).and_return(staff_account)
    end

    it "grants access to comment moderation" do
      get "#{comment.path}/mod"
      expect(response).to have_http_status(:ok)
    end

    it "grant access to article moderation" do
      get "#{article.path}/mod"
      expect(response).to have_http_status(:ok)
    end

    it "grants access to /mod index" do
      create(:rating_vote, article: article, user: trusted_user)
      get "/mod"
      expect(response).to have_http_status(:ok)
    end

    it "grants access to /mod index with articles" do
      article = create(:article, published: true)
      get "/mod"
      expect(response.body).to include(CGI.escapeHTML(article.title))
    end

    it "grants access to /mod/:tag index with articles" do
      create(:article, published: true)
      get "/mod/#{article.tags.first}"
      expect(response.body).to include("##{article.tags.first.name}")
      expect(response.body).to include(CGI.escapeHTML(article.title))
    end

    it "returns not found for inappropriate tags" do
      expect { get "/mod/dsdsdsweweedsdseweww" }.to raise_exception(ActiveRecord::RecordNotFound)
    end

    it "renders not_found when an article can't be found" do
      expect do
        get "/#{trusted_user.username}/dsdsdsweweedsdseweww/mod/"
      end.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  describe "actions_panel" do
    context "when the user is a tag moderator" do
      let(:tag_mod) { create(:user, :tag_moderator) }
      let(:tag) { tag_mod.roles.find_by(name: "tag_moderator").resource }
      let(:article1) { create(:article, tags: tag) }
      let(:article2) { create(:article, tags: "javascript, cool, beans") }

      it "shows the option to remove the tag when the article has the tag" do
        tag_mod.add_role(:trusted)
        sign_in tag_mod

        get "#{article1.path}/actions_panel"
        expect(response.body).to include "circle centered-icon adjustment-icon subtract"
      end

      it "shows the option to add the tag when the article has the tag" do
        tag_mod.add_role(:trusted)
        sign_in tag_mod

        get "#{article2.path}/actions_panel"
        expect(response.body).to include "circle centered-icon adjustment-icon plus"
      end
    end
  end

  context "when the user is trusted" do
    before do
      sign_in trusted_user
      get "#{article.path}/actions_panel"
    end

    it "does not show the adjust tags options" do
      expect(response.body).not_to include "other-things-btn adjust-tags"
    end

    it "shows the experience level option" do
      expect(response.body).to include "other-things-btn set-experience"
    end
  end

  context "when the user is an admin" do
    let(:admin) { create(:user, :admin) }
    let(:article) { create(:article, tags: "javascript, cool, beans") }

    before do
      sign_in admin
      get "#{article.path}/actions_panel"
    end

    it "shows the admin tag options", :aggregate_failures do
      expect(response.body).to include "admin-add-tag"
      expect(response.body).to include "circle centered-icon adjustment-icon subtract"
    end
  end

  describe "/mod" do
    let(:dev_name_copy) { "We periodically award some DEV members with heightened privileges" }
    # rubocop:disable Layout/LineLength
    let(:coc_guides_copy) do
      'Check out our <a href="/code-of-conduct">Code of Conduct</a> and read through our <a href="/community-moderation">Trusted User Guide</a> and <a href="/tag-moderation">Tag Moderation Guide</a>.'
    end
    # rubocop:enable Layout/LineLength
    let(:become_mod_copy) { "If you'd like to assist us as a trusted user or tag mod" }
    let(:logged_out_copy) { "P.S. You are not currently signed in." }
    let(:user) { create(:user) }

    before do
      allow(Settings::Community).to receive(:community_name).and_return("DEV")
    end

    context "when user logged in" do
      it "indicates community name, codes of conduct/guides, and describes how to become a mod" do
        sign_in user
        get "/mod"

        expect(response.body).to include dev_name_copy
        expect(response.body).to include coc_guides_copy
        expect(response.body).to include become_mod_copy
        expect(response.body).not_to include logged_out_copy
      end
    end

    context "when user logged out" do
      it "warns that user is not signed in" do
        get "/mod"

        expect(response.body).to include logged_out_copy
      end
    end
  end

  describe "Super moderator Note & AuditLog" do
    let(:super_mod) { create(:user, :super_moderator) }

    before do
      sign_in super_mod
      Audit::Subscribe.listen(:moderator)
    end

    after { Audit::Subscribe.forget(:moderator) }

    context "when unpublish a post of user" do
      it "creates a note on a user" do
        expected_note = "#{super_mod.username} unpublished post with ID #{article.id}"
        expect do
          patch "/articles/#{article.id}/admin_unpublish",
                params: { slug: article.slug, username: article.user.username }
        end.to change(Note, :count).by(1)
        expect(Note.last.content).to eq(expected_note)
      end

      it "creates an AuditLog for the action taken" do
        expect do
          patch "/articles/#{article.id}/admin_unpublish",
                params: { slug: article.slug, username: article.user.username }
        end.to change(AuditLog, :count).by(1)
      end
    end

    context "when unpublish all posts of user" do
      it "creates a note on a user when note content is provided" do
        note_content = "Unpublish due to Spam"
        expect do
          post "/admin/member_manager/users/#{article.user_id}/unpublish_all_articles",
               params: { note: { content: note_content } }
        end.to change(Note, :count).by(1)
        expect(Note.last.content).to eq(note_content)
      end

      it "creates a default note on a user when note content isn't provided" do
        expected_note = "#{super_mod.username} unpublished all articles"
        expect do
          post "/admin/member_manager/users/#{article.user_id}/unpublish_all_articles"
        end.to change(Note, :count).by(1)
        expect(Note.last.content).to eq(expected_note)
      end

      it "creates an AuditLog for the action taken" do
        expect do
          post "/admin/member_manager/users/#{article.user_id}/unpublish_all_articles",
               params: { note: { content: "Test note" } }
          sidekiq_perform_enqueued_jobs
        end.to change(AuditLog, :count).by(1)
      end
    end

    context "when suspend user" do
      it "creates a note on a user when note content is provided" do
        note_content = "Unpublish due to Spam"
        expect do
          patch "/admin/member_manager/users/#{article.user_id}/user_status",
                params: { user: { user_status: "Suspend", note_for_current_role: note_content } }
        end.to change(Note, :count).by(1)
        expect(Note.last.content).to eq(note_content)
      end

      it "creates a default note on a user when note content isn't provided" do
        expected_note = "#{super_mod.username} updated #{article.user.username}"
        expect do
          patch "/admin/member_manager/users/#{article.user_id}/user_status",
                params: { user: { user_status: "Suspend" } }
        end.to change(Note, :count).by(1)
        expect(Note.last.content).to eq(expected_note)
      end

      it "creates an AuditLog for the action taken" do
        expect do
          patch "/admin/member_manager/users/#{article.user_id}/user_status",
                params: { user: { user_status: "Suspend", new_note: "Test note" } }
        end.to change(AuditLog, :count).by(1)
      end
    end
  end
end
