require "rails_helper"

RSpec.describe "Subforems", type: :request do
  describe "GET /subforems" do
    let!(:root_subforem)         { create(:subforem, root: true,  discoverable: true, domain: "#{rand(1000)}.com") }
    let!(:discoverable_subforem) { create(:subforem, root: false, discoverable: true,  domain: "#{rand(1000)}.com") }
    let!(:hidden_subforem)       { create(:subforem, root: false, discoverable: false, domain: "#{rand(1000)}.com") }

    before { get subforems_path }

    it "returns http success" do
      expect(response).to have_http_status(:ok)
    end

    it "renders only discoverable and root subforems" do
      # should include the domains for root & discoverable, but not the hidden one
      expect(response.body).to include(root_subforem.domain)
      expect(response.body).to include(discoverable_subforem.domain)
      expect(response.body).not_to include(hidden_subforem.domain)
    end

    it "orders root subforems first and then by id asc" do
      # ensure the root subforem's domain appears before the discoverable one
      root_pos          = response.body.index(root_subforem.domain)
      discoverable_pos  = response.body.index(discoverable_subforem.domain)
      expect(root_pos).to be < discoverable_pos
    end

    it "sets the Surrogate‑Key header with table and record keys" do
      expected_values = [
        "subforems",
        Subforem.table_key,
        root_subforem.record_key,
        discoverable_subforem.record_key
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
