require "rails_helper"

RSpec.describe "Subforems", type: :request do
  describe "GET /subforems" do
    let!(:root_subforem)         { create(:subforem, root: true,  discoverable: true, domain: "#{rand(10000)}.com") }
    let!(:discoverable_subforem) { create(:subforem, root: false, discoverable: true,  domain: "#{rand(10000)}.com", score: 3) }
    let!(:discoverable_subforem_second) { create(:subforem, root: false, discoverable: true,  domain: "#{rand(10000)}.com", score: 2) }
    let!(:hidden_subforem)       { create(:subforem, root: false, discoverable: false, domain: "#{rand(10000)}.com") }

    before { get subforems_path }

    it "returns http success" do
      expect(response).to have_http_status(:ok)
    end

    it "renders only discoverable" do
      # should include the domains for root & discoverable, but not the hidden one
      expect(response.body).to include(discoverable_subforem.domain)
      expect(response.body).not_to include(hidden_subforem.domain)
    end

    it "sets the Surrogate‑Key header with table and record keys" do
      expected_values = [
        "subforems",
        Subforem.table_key,
        discoverable_subforem.record_key,
        discoverable_subforem_second.record_key,
      ]
      expect(response.headers["Surrogate-Key"]).to eq(expected_values.join(" "))
    end
  end

  context "when no subforems are available" do
    before do
      Subforem.delete_all
      get subforems_path
    end

    it "renders a no subforems available message" do
      expect(response.body).to include("No subforems available")
    end
  end
end
