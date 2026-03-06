require "rails_helper"

RSpec.describe "/admin/apps/keyword-trends" do
  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "blocks the request" do
      expect do
        get admin_keyword_trends_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }
    let(:term) { "keyword-trend-terraform" }
    let(:month) { 2.months.ago.beginning_of_month }

    before do
      create(:article, title: "Learning #{term}", body_markdown: "A post about #{term}", published: true, published_at: month)
      create(:article, title: "Another topic", body_markdown: "No keyword here", published: true, published_at: month)
      create(:article, title: "Draft #{term}", body_markdown: "Draft", published: false, published_at: month)
      sign_in super_admin
      get admin_keyword_trends_path, params: { term: term, start_month: month.strftime("%Y-%m"), end_month: month.strftime("%Y-%m") }
    end

    it "allows the request" do
      expect(response).to have_http_status(:ok)
    end

    it "shows totals and monthly raw data for matching published articles" do
      expect(response.body).to include("Total matches: <strong>1</strong>")
      expect(response.body).to include(month.strftime("%Y-%m"))
      expect(response.body).to include("<td>1</td>")
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: KeywordTrend) }

    before do
      sign_in single_resource_admin
      get admin_keyword_trends_path
    end

    it "allows the request" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is the wrong single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Article) }

    before do
      sign_in single_resource_admin
    end

    it "blocks the request" do
      expect do
        get admin_keyword_trends_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
