require "rails_helper"

RSpec.describe "HtmlVariantTrials", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id, approved: true) }
  let(:html_variant) { create(:html_variant) }

  before do
    Delayed::Worker.delay_jobs = false
  end

  after do
    Delayed::Worker.delay_jobs = true
  end

  describe "POST /html_variant_trials" do
    it "rejects non-permissioned user" do
      post "/html_variant_trials", params: {
        article_id: article.id,
        html_variant_id: html_variant.id
      }
      expect(HtmlVariantTrial.all.size).to eq(1)
    end
  end
end
