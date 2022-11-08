require "rails_helper"

RSpec.describe "PageViews", type: :request do
  let(:user) { create(:user, :trusted) }
  let(:article) { create(:article) }

  def page_views_post(params)
    sidekiq_perform_enqueued_jobs do
      post "/page_views", params: params
    end
    # Also drain Articles::UpdateOrganicPageViewsWorker if any were enqueued
    sidekiq_perform_enqueued_jobs(only: Articles::UpdateOrganicPageViewsWorker)
  end

  describe "POST /page_views" do
    context "when user signed in" do
      before do
        sign_in user
      end

      it "creates a new page view", :aggregate_failures do
        page_views_post(article_id: article.id)

        expect(article.reload.page_views.size).to eq(1)
        expect(article.reload.page_views_count).to eq(1)
        expect(user.reload.page_views.size).to eq(1)
        expect(PageView.last.counts_for_number_of_views).to eq(1)
      end

      it "sends referrer" do
        page_views_post(article_id: article.id, referrer: "test")

        expect(PageView.last.referrer).to eq("test")
      end

      it "sends user agent" do
        page_views_post(article_id: article.id, user_agent: "test")

        expect(PageView.last.user_agent).to eq("test")
      end
    end

    context "when part of field test" do
      before do
        sign_in user
        allow(Users::RecordFieldTestEventWorker).to receive(:perform_async)
      end

      it "converts field test" do
        page_views_post(article_id: article.id, referrer: "test")

        expect(Users::RecordFieldTestEventWorker).to have_received(:perform_async)
          .with(user.id, "user_creates_pageview")
      end
    end

    context "when not part of field test" do
      before do
        sign_in user
        allow(FieldTest).to receive(:config).and_return({ "experiments" => nil })
        allow(Users::RecordFieldTestEventWorker).to receive(:perform_async)
      end

      it "converts field test" do
        page_views_post(article_id: article.id, referrer: "test")

        expect(Users::RecordFieldTestEventWorker).not_to have_received(:perform_async)
      end
    end

    context "when user not signed in", :aggregate_failures do
      it "creates a new page view" do
        page_views_post(article_id: article.id)

        expect(article.reload.page_views.size).to eq(1)
        expect(article.reload.page_views_count).to eq(10)
        expect(user.reload.page_views.size).to eq(0)
        expect(PageView.last.counts_for_number_of_views).to eq(10)
      end

      it "stores aggregate page views" do
        page_views_post(article_id: article.id)
        page_views_post(article_id: article.id)

        expect(article.reload.page_views_count).to eq(20)
      end

      it "stores aggregate organic page views", :aggregate_failures do
        page_views_post(article_id: article.id, referrer: "https://www.google.com/")
        page_views_post(article_id: article.id)

        expect(article.reload.organic_page_views_past_month_count).to eq(10)
      end

      it "sends referrer" do
        page_views_post(article_id: article.id, referrer: "test")

        expect(PageView.last.referrer).to eq("test")
      end

      it "sends user agent" do
        page_views_post(article_id: article.id, user_agent: "test")

        expect(PageView.last.user_agent).to eq("test")
      end
    end
  end

  describe "PUT /page_views/:id" do
    context "when user is signed in" do
      before do
        sign_in user
      end

      it "updates a new page view time on page by 15" do
        page_views_post(article_id: article.id)

        put "/page_views/#{article.id}"

        expect(PageView.last.time_tracked_in_seconds).to eq(30)
      end

      it "does not update an invalid page view" do
        invalid_id = article.id + 100

        expect { put "/page_views/#{invalid_id}" }.not_to raise_error
      end
    end

    context "when user is not signed in" do
      it "updates a new page view time on page by 15" do
        page_views_post(article_id: article.id)
        put "/page_views/#{article.id}"

        expect(PageView.last.time_tracked_in_seconds).to eq(15)
      end
    end
  end
end
