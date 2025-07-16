require "rails_helper"

RSpec.describe "Subforems", type: :request do
  describe "GET /subforems" do
    let!(:root_subforem)        { create(:subforem, root: true, discoverable: false, domain: "#{rand(1000)}.com") }
    let!(:discoverable_subforem){ create(:subforem, root: false, discoverable: true, domain: "#{rand(1000)}.com") }
    let!(:hidden_subforem)      { create(:subforem, root: false, discoverable: false, domain: "#{rand(1000)}.com") }

    it "returns http success and only includes discoverable and root subforems" do
      get subforems_path

      expect(response).to have_http_status(:ok)
      subforems = assigns(:subforems)
      expect(subforems).to match_array([root_subforem, discoverable_subforem])
    end

    it "orders root subforems first (by root desc) then by id asc" do
      get subforems_path

      subforems = assigns(:subforems)
      expected_order = [root_subforem, discoverable_subforem].sort_by { |s| [s.root ? 0 : 1, s.id] }
      expect(subforems).to eq(expected_order)
    end

    it "sets the Surrogate-Key header with table and record keys" do
      get subforems_path

      subforems = assigns(:subforems)
      expected_values = ["subforems", Subforem.table_key, *subforems.map(&:record_key)]
      expect(response.headers["Surrogate-Key"]).to eq(expected_values.join(" "))
    end
  end

  context "when no subforems are available" do
    before { Subforem.delete_all }

    it "renders a no subforems available message" do
      get subforems_path

      expect(response.body).to include("No subforems available")
    end
  end
end
