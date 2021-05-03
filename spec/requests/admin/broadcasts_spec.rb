require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/advanced/broadcasts", type: :request do
  let(:get_resource) { get admin_broadcasts_path }
  let(:params) { { title: "Hello!", processed_html: "<p>Hello!</p>", type_of: "Welcome", active: true } }
  let(:post_resource) { post admin_broadcasts_path, params: params }

  it_behaves_like "an InternalPolicy dependant request", Broadcast do
    let(:request) { get_resource }
  end

  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before { sign_in user }

    describe "GET /admin/advanced/broadcasts" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /admin/advanced/broadcasts" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }

    before { sign_in super_admin }

    describe "GET /admin/advanced/broadcasts" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/advanced/broadcasts" do
      it "creates a new broadcast" do
        expect do
          post_resource
        end.to change { Broadcast.all.count }.by(1)
      end
    end

    describe "PUT /admin/advanced/broadcasts" do
      let!(:broadcast) { create(:welcome_broadcast, active: false) }

      it "updates the Broadcast's active_status_updated_at timestamp" do
        old_time = broadcast.active_status_updated_at
        Timecop.freeze(Time.current) do
          expect do
            put admin_broadcast_path(broadcast.id), params: params
          end.to change { broadcast.reload.active }.from(false).to(true)
          expect(broadcast.active_status_updated_at).not_to eq(old_time)
        end
      end
    end

    describe "DELETE /admin/advanced/broadcasts/:id" do
      let!(:broadcast) { create(:welcome_broadcast) }

      it "deletes the broadcast" do
        expect do
          delete admin_broadcast_path(broadcast.id)
        end.to change { Broadcast.all.count }.by(-1)
        expect(response.body).to redirect_to admin_broadcasts_path
      end
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Broadcast) }

    before { sign_in single_resource_admin }

    describe "GET /admin/advanced/broadcasts" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/advanced/broadcasts" do
      it "creates a new broadcast" do
        expect do
          post_resource
        end.to change { Broadcast.all.count }.by(1)
      end
    end

    describe "DELETE /admin/advanced/broadcasts/:id" do
      let!(:broadcast) { create(:welcome_broadcast) }

      it "deletes the broadcast" do
        expect do
          delete admin_broadcast_path(broadcast.id)
        end.to change { Broadcast.all.count }.by(-1)
        expect(response.body).to redirect_to admin_broadcasts_path
      end
    end
  end

  context "when the user is the wrong single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Article) }

    before { sign_in single_resource_admin }

    describe "GET /admin/advanced/broadcasts" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /admin/advanced/broadcasts" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context "with type_of Announcement" do
    let(:super_admin) { create(:user, :super_admin) }
    let(:params) { { title: "Hello!", processed_html: "<p>Hello!</p>", type_of: "Announcement", active: true } }

    before { sign_in super_admin }

    context "when an announcement broadcast is already active" do
      before { create(:announcement_broadcast) }

      it "does not allow a second broadcast to be set to active" do
        expect do
          post_resource
        end.to change { Broadcast.all.count }.by(0)
      end
    end

    context "when no announcement broadcast is active" do
      it "allows a broadcast to be set to active" do
        expect do
          post_resource
        end.to change { Broadcast.all.count }.by(1)
      end
    end
  end

  context "with the same title and the same type_of" do
    let(:super_admin) { create(:user, :super_admin) }
    let(:params) { { title: "Hello!", processed_html: "<p>Hello!</p>", type_of: "Announcement" } }

    before { sign_in super_admin }

    it "does not allow for a second broadcast to be created" do
      expect do
        2.times do
          post_resource
        end
      end.to change { Broadcast.all.count }.by(1)
    end
  end
end
