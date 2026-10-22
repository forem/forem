require "rails_helper"

RSpec.describe "FlagAppeals" do
  let(:user) { create(:user) }

  describe "GET /appeal" do
    context "when user is not authenticated" do
      it "redirects to sign in / magic link" do
        get appeal_path
        expect(response).to redirect_to(new_magic_link_path)
      end
    end

    context "when user is not suspended" do
      before { sign_in user }

      it "redirects to root_path without showing the appeal form" do
        get appeal_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when user is suspended" do
      before do
        user.add_role(:suspended)
        sign_in user
      end

      it "renders the new appeal page with no-cache headers" do
        get appeal_path
        expect(response).to have_http_status(:ok)
        expect(response.headers["Cache-Control"]).to include("no-store")
        expect(response.body).to include("Submit a Moderation Appeal")
      end
    end
  end

  describe "POST /appeal" do
    before do
      user.add_role(:suspended)
      sign_in user
    end

    it "redirects to root_path without creating a FlagAppeal when the user is not suspended" do
      user.remove_role(:suspended)

      expect do
        post appeal_path, params: {
          flag_appeal: { reason: "Trying to appeal while not suspended" }
        }
      end.not_to change(FlagAppeal, :count)

      expect(response).to redirect_to(root_path)
    end

    context "with valid parameters" do
      it "creates a FlagAppeal for current_user and redirects to appeal success page" do
        expect do
          post appeal_path, params: {
            flag_appeal: {
              reason: "My account was suspended by mistake."
            }
          }
        end.to change(FlagAppeal, :count).by(1)

        appeal = FlagAppeal.last
        expect(appeal.appealable).to eq(user)
        expect(response).to redirect_to(appeal_success_path(id: appeal.id))
        expect(flash[:notice]).to be_present
      end

      it "ignores forged appealable_type and appealable_id parameters and binds to current_user" do
        other_user = create(:user)
        post appeal_path, params: {
          flag_appeal: {
            reason: "Attempting to appeal another resource",
            appealable_type: "User",
            appealable_id: other_user.id
          }
        }

        appeal = FlagAppeal.last
        expect(appeal.appealable).to eq(user)
      end
    end

    context "with invalid parameters" do
      it "renders new with unprocessable_entity status" do
        post appeal_path, params: {
          flag_appeal: { reason: "" }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when rate limiting appeal creation" do
      let(:cache) { ActiveSupport::Cache.lookup_store(:memory_store) }
      let(:limit) { Settings::RateLimit.flag_appeal_creation }

      def file_appeal
        post appeal_path, params: {
          flag_appeal: { reason: "This was a false positive." }
        }
      end

      before do
        allow(Rails).to receive(:cache).and_return(cache)
        allow(Appeals::AiReviewWorker).to receive(:perform_async)
      end

      it "blocks appeals beyond the limit without queueing an AI review" do
        (limit + 1).times do
          file_appeal
          FlagAppeal.where(user: user).update_all(status: FlagAppeal.statuses[:rejected])
        end
        expect(FlagAppeal.where(user: user).count).to eq(limit + 1)

        expect { file_appeal }.not_to change(FlagAppeal, :count)

        expect(response).to have_http_status(:too_many_requests)
        expect(response.headers["Retry-After"]).to eq(RateLimitChecker::ACTION_LIMITERS
          .dig(:flag_appeal_creation, :retry_after).to_s)
        limit_message = I18n.t("services.rate_limit_checker.limit_reached", count: 300)
        expect(response.body).to include(CGI.escapeHTML(limit_message))
        expect(Appeals::AiReviewWorker).to have_received(:perform_async).exactly(limit + 1).times
      end

      it "only counts appeals that were saved" do
        allow(Settings::RateLimit).to receive(:flag_appeal_creation).and_return(0)

        post appeal_path, params: { flag_appeal: { reason: "" } }
        expect(response).to have_http_status(:unprocessable_entity)

        expect { file_appeal }.to change(FlagAppeal, :count).by(1)
        expect(response).to redirect_to(appeal_success_path(id: FlagAppeal.last.id))
      end
    end
  end

  describe "GET /appeal/submitted" do
    let!(:appeal) { create(:flag_appeal, user: user) }

    before { sign_in user }

    it "renders post-submission confirmation landing page with no-cache headers" do
      get appeal_success_path(id: appeal.id)
      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(response.body).to include("Thank you for your appeal submission")
    end

    it "redirects to root when accessing another user's appeal" do
      other_user_appeal = create(:flag_appeal)
      get appeal_success_path(id: other_user_appeal.id)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "the forbidden page shown to restricted users" do
    before do
      user.add_role(:suspended)
      sign_in user
    end

    it "links to the appeal form inside the standard page container with no-cache headers" do
      get new_path

      page = Nokogiri::HTML(response.body)
      expect(response).to have_http_status(:forbidden)
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(response.headers["Surrogate-Control"]).to be_nil
      expect(page.css("main#main-content.crayons-layout .crayons-card h1").text).to eq("Forbidden")
      expect(page.at_css("main#main-content a[href='#{appeal_path}']")).to be_present
    end
  end

  describe "suspended account notice on dashboard and settings" do
    before { sign_in user }

    it "shows the suspended account notice on the dashboard and settings pages when actively suspended" do
      create(:article, user: user)
      user.add_role(:suspended)

      get dashboard_path
      expect(response.headers["Cache-Control"]).to include("no-store")
      dashboard_notice = Nokogiri::HTML(response.body).at_css("[data-testid='suspended-account-notice']")
      expect(dashboard_notice&.at_css("a[href='#{appeal_path}']")).to be_present

      get dashboard_following_tags_path
      expect(Nokogiri::HTML(response.body).at_css("[data-testid='suspended-account-notice']")).to be_present

      get user_settings_path
      expect(response.headers["Cache-Control"]).to include("no-store")
      settings_notice = Nokogiri::HTML(response.body).at_css("[data-testid='suspended-account-notice']")
      expect(settings_notice&.at_css("a[href='#{appeal_path}']")).to be_present
    end

    it "does not show the suspended notice to non-suspended users or after suspension is lifted" do
      create(:article, user: user)

      get dashboard_path
      expect(Nokogiri::HTML(response.body).at_css("[data-testid='suspended-account-notice']")).to be_nil

      get user_settings_path
      expect(Nokogiri::HTML(response.body).at_css("[data-testid='suspended-account-notice']")).to be_nil

      user.add_role(:suspended)
      user.remove_role(:suspended)

      get user_settings_path
      expect(Nokogiri::HTML(response.body).at_css("[data-testid='suspended-account-notice']")).to be_nil
    end

    it "does not show the notice or trust a stale role_names cache entry if the user is not suspended in the DB" do
      cache = ActiveSupport::Cache.lookup_store(:memory_store)
      allow(Rails).to receive(:cache).and_return(cache)
      cache.write("user-#{user.id}/role_names", ["suspended"])

      expect(user.actively_suspended?).to be false
      expect(cache.read("user-#{user.id}/role_names")).to be_nil
    end

    it "short-circuits via cached_role_names without querying roles for non-suspended users" do
      cache = ActiveSupport::Cache.lookup_store(:memory_store)
      allow(Rails).to receive(:cache).and_return(cache)
      cache.write("user-#{user.id}/role_names", [])
      allow(user).to receive(:suspended?).and_call_original

      expect(user.actively_suspended?).to be false
      expect(user).not_to have_received(:suspended?)
    end
  end
end
