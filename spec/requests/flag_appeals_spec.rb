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

    context "when user is authenticated" do
      before { sign_in user }

      it "renders the new appeal page successfully" do
        get appeal_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Submit a Moderation Appeal")
      end

      it "does not expose another user's article through appealable_id" do
        other_article = create(:article, user: create(:user), title: "Someone Else's Private Draft Title")

        get appeal_path(appealable_type: "Article", appealable_id: other_article.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(other_article.title)
        expect(response.body).to include("value=\"User\"")
      end

      it "does not expose another user's comment through appealable_id" do
        other_comment = create(:comment, user: create(:user), body_markdown: "Someone else's secret comment body")

        get appeal_path(appealable_type: "Comment", appealable_id: other_comment.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("secret comment body")
      end

      it "pre-fills the target from the Fastly-safe source_type and source_id params" do
        comment = create(:comment, user: user)

        get appeal_path(source_type: "Comment", source_id: comment.id)

        page = Nokogiri::HTML(response.body)
        expect(page.at_css("input[name='flag_appeal[appealable_type]']")["value"]).to eq("Comment")
        expect(page.at_css("input[name='flag_appeal[appealable_id]']")["value"]).to eq(comment.id.to_s)
      end

      it "does not expose another user's comment through source_id" do
        other_comment = create(:comment, user: create(:user), body_markdown: "Someone else's secret comment body")

        get appeal_path(source_type: "Comment", source_id: other_comment.id)

        page = Nokogiri::HTML(response.body)
        expect(page.at_css("input[name='flag_appeal[appealable_type]']")["value"]).to eq("User")
        expect(page.at_css("input[name='flag_appeal[appealable_id]']")["value"]).to eq(user.id.to_s)
      end
    end
  end

  describe "POST /appeal" do
    before { sign_in user }

    context "with valid parameters" do
      it "creates a FlagAppeal and redirects to appeal success page" do
        expect do
          post appeal_path, params: {
            flag_appeal: {
              reason: "My post was not spam, it was technical documentation.",
              appealable_type: "User",
              appealable_id: user.id
            }
          }
        end.to change(FlagAppeal, :count).by(1)

        appeal = FlagAppeal.last
        expect(response).to redirect_to(appeal_success_path(id: appeal.id))
        expect(flash[:notice]).to be_present
      end

      it "creates a FlagAppeal for a Comment target" do
        comment = create(:comment, user: user)
        expect do
          post appeal_path, params: {
            flag_appeal: {
              reason: "My comment code example was not spam.",
              appealable_type: "Comment",
              appealable_id: comment.id
            }
          }
        end.to change(FlagAppeal, :count).by(1)

        appeal = FlagAppeal.last
        expect(appeal.appealable_type).to eq("Comment")
        expect(appeal.appealable_id).to eq(comment.id)
        expect(response).to redirect_to(appeal_success_path(id: appeal.id))
      end

      it "sanitizes unauthorized appealable_id to current_user to prevent IDOR on articles" do
        other_user_article = create(:article)
        post appeal_path, params: {
          flag_appeal: {
            reason: "Attempting to appeal another user's article",
            appealable_type: "Article",
            appealable_id: other_user_article.id
          }
        }

        appeal = FlagAppeal.last
        expect(appeal.appealable_type).to eq("User")
        expect(appeal.appealable_id).to eq(user.id)
      end

      it "sanitizes unauthorized appealable_id to current_user to prevent IDOR on comments" do
        other_user_comment = create(:comment)
        post appeal_path, params: {
          flag_appeal: {
            reason: "Attempting to appeal another user's comment",
            appealable_type: "Comment",
            appealable_id: other_user_comment.id
          }
        }

        appeal = FlagAppeal.last
        expect(appeal.appealable_type).to eq("User")
        expect(appeal.appealable_id).to eq(user.id)
      end
    end

    context "with invalid parameters" do
      it "renders new with unprocessable_entity status" do
        post appeal_path, params: {
          flag_appeal: {
            reason: "",
            appealable_type: "User",
            appealable_id: user.id
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when rate limiting appeal creation" do
      let(:cache) { ActiveSupport::Cache.lookup_store(:memory_store) }
      let(:limit) { Settings::RateLimit.flag_appeal_creation }

      def file_appeal(target)
        post appeal_path, params: {
          flag_appeal: {
            reason: "This was a false positive.",
            appealable_type: target.class.name,
            appealable_id: target.id
          }
        }
      end

      before do
        allow(Rails).to receive(:cache).and_return(cache)
        allow(Appeals::AiReviewWorker).to receive(:perform_async)
      end

      it "blocks appeals beyond the limit across different targets without queueing an AI review" do
        targets = [user] + create_list(:article, limit, user: user)
        targets.each { |target| file_appeal(target) }
        expect(FlagAppeal.where(user: user).count).to eq(limit + 1)

        extra_target = create(:comment, user: user)
        expect { file_appeal(extra_target) }.not_to change(FlagAppeal, :count)

        expect(response).to have_http_status(:too_many_requests)
        expect(response.headers["Retry-After"]).to eq(RateLimitChecker::ACTION_LIMITERS
          .dig(:flag_appeal_creation, :retry_after).to_s)
        limit_message = I18n.t("services.rate_limit_checker.limit_reached", count: 300)
        expect(response.body).to include(CGI.escapeHTML(limit_message))
        expect(Appeals::AiReviewWorker).to have_received(:perform_async).exactly(limit + 1).times
      end

      it "only counts appeals that were saved" do
        allow(Settings::RateLimit).to receive(:flag_appeal_creation).and_return(0)

        post appeal_path, params: { flag_appeal: { reason: "", appealable_type: "User", appealable_id: user.id } }
        expect(response).to have_http_status(:unprocessable_entity)

        expect { file_appeal(user) }.to change(FlagAppeal, :count).by(1)
        expect(response).to redirect_to(appeal_success_path(id: FlagAppeal.last.id))
      end
    end
  end

  describe "GET /appeal/success" do
    let!(:appeal) { create(:flag_appeal, user: user) }

    before { sign_in user }

    it "renders post-submission confirmation landing page" do
      get appeal_success_path(id: appeal.id)
      expect(response).to have_http_status(:ok)
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

    it "links to the appeal form inside the standard page container" do
      get new_path

      page = Nokogiri::HTML(response.body)
      expect(response).to have_http_status(:forbidden)
      expect(page.css("main#main-content.crayons-layout .crayons-card h1").text).to eq("Forbidden")
      expect(page.at_css("main#main-content a[href='#{appeal_path}']")).to be_present
    end
  end
end
