require "rails_helper"

RSpec.describe "Admin::Events", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:regular_user) { create(:user) }
  
  describe "GET /admin/content_manager/events" do
    context "when logged in as an admin" do
      before { login_as(super_admin) }

      it "renders the index template" do
        create(:event)
        get admin_events_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when logged in as a normal user" do
      before { login_as(regular_user) }

      it "denies access" do
        expect {
          get admin_events_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/content_manager/events/:id" do
    let(:event) { create(:event) }

    context "when logged in as an admin" do
      before { login_as(super_admin) }

      it "renders the show template" do
        get admin_event_path(event)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(event.title)
      end
    end

    context "when logged in as a normal user" do
      before { login_as(regular_user) }

      it "denies access" do
        expect {
          get admin_event_path(event)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/content_manager/events" do
    before { login_as(super_admin) }

    let(:valid_attributes) do
      {
        title: "Test Admin Event",
        description: "Testing admin creation",
        event_name_slug: "test-admin",
        event_variation_slug: "v1",
        start_time: 1.day.from_now,
        end_time: 2.days.from_now,
        published: true
      }
    end

    it "creates a new Event" do
      expect {
        post admin_events_path, params: { event: valid_attributes }
      }.to change(Event, :count).by(1)
      
      expect(response).to redirect_to(admin_events_path)
      expect(Event.last.event_name_slug).to eq("test-admin")
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { valid_attributes.merge(title: "") }

      it "does not create a new event and returns unprocessable_entity with an error message" do
        expect {
          post admin_events_path, params: { event: invalid_attributes }
        }.not_to change(Event, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("prohibited this event from being saved")
      end
    end
  end
end
