require "rails_helper"

RSpec.describe "/admin/data_update_scripts", type: :request do
  let(:get_resource) { get "/admin/data_update_scripts" }

  context "when the user is not an tech admin" do
    let(:user) { create(:user) }

    before { sign_in user }

    describe "GET /admin/data_update_scripts" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(StandardError)
      end
    end
  end

  context "when the user is a tech admin" do
    let(:user) { create(:user, :admin, :tech_admin) }

    before { sign_in user }

    describe "GET /admin/data_update_scripts" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end

      it "displays the data_update_scripts" do
        script = create(:data_update_script)
        get_resource

        expect(response.body).to include(script.id.to_s)
        expect(response.body).to include(script.run_at.to_s)
        expect(response.body).to include(script.created_at.to_s)
        expect(response.body).to include(script.status.to_s)
      end

      it "displays a 'Rerun' button when the script status is failed" do
        create(:data_update_script, status: "failed")
        get_resource
        expect(response.body).to include("Re-run")
      end
    end

    describe "GET /admin/data_update_scripts/:id" do
      let(:script) do
        create(
          :data_update_script,
          file_name: "20200214151804_data_update_test_script",
          status: "succeeded",
        )
      end
      let(:script_id) { script.id }

      it "returns a data update script" do
        get admin_data_update_script_path(id: script_id)

        expect(response).to have_http_status(:ok)
        expect(script.id).to eq(response.parsed_body["response"]["id"])
        expect(script.file_name).to eq(response.parsed_body["response"]["file_name"])
        expect(script.status).to eq(response.parsed_body["response"]["status"])
      end
    end

    describe "POST /admin/:id/force_run" do
      let(:script) { create(:data_update_script, file_name: "20200214151804_data_update_test_script") }
      let(:script_id) { script.id.to_s }

      it "calls the the sidekiq worker" do
        allow(DataUpdateWorker).to receive(:perform_async)

        post "/admin/data_update_scripts/#{script_id}/force_run"
        sidekiq_perform_enqueued_jobs

        expect(DataUpdateWorker).to have_received(:perform_async).with(script_id)
      end
    end
  end
end
