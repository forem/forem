require "rails_helper"

RSpec.describe "/admin/audience_segments" do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let!(:manual_segment) { create(:audience_segment, name: "Alpha Testers") }
  let!(:system_segment) { create(:audience_segment, type_of: :trusted, name: nil) }

  context "when not signed in" do
    it "raises unauthorized error" do
      expect do
        get admin_audience_segments_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when signed in as a non-admin user" do
    before { sign_in regular_user }

    it "raises or redirects with unauthorized" do
      expect do
        get admin_audience_segments_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when signed in as admin" do
    before { sign_in admin_user }

    describe "GET /admin/audience_segments" do
      it "renders the index page with manual and system segments" do
        get admin_audience_segments_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Alpha Testers")
        expect(response.body).to include(system_segment.display_name)
      end

      it "filters custom segments by search term" do
        create(:audience_segment, name: "Beta Testers")
        get admin_audience_segments_path, params: { search: "Alpha" }
        expect(response.body).to include("Alpha Testers")
        expect(response.body).not_to include("Beta Testers")
      end
    end

    describe "GET /admin/audience_segments/new" do
      it "renders the new template" do
        get new_admin_audience_segment_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('name="audience_segment[name]"')
        expect(response.body).to include('name="user_identifiers"')
      end
    end

    describe "POST /admin/audience_segments" do
      let!(:user1) { create(:user, username: "devuser1") }
      let!(:user2) { create(:user, username: "devuser2") }

      it "creates a new manual audience segment without initial users" do
        expect do
          post admin_audience_segments_path, params: {
            audience_segment: { name: "New Segment" }
          }
        end.to change(AudienceSegment, :count).by(1)

        created = AudienceSegment.last
        expect(created.name).to eq("New Segment")
        expect(created).to be_manual
        expect(response).to redirect_to(admin_audience_segment_path(created))
        follow_redirect!
        expect(flash[:success]).to eq(I18n.t("admin.audience_segments_controller.created"))
      end

      it "creates a new segment and bulk adds initial users from text input" do
        expect do
          post admin_audience_segments_path, params: {
            audience_segment: { name: "Segment with Users" },
            user_identifiers: "@devuser1, #{user2.email}"
          }
        end.to change(AudienceSegment, :count).by(1)

        created = AudienceSegment.last
        expect(created.users).to contain_exactly(user1, user2)
        expect(flash[:success]).to include("Segment created with 2 user(s).")
      end

      it "creates a new segment populated from a UserQuery" do
        query = create(:user_query, name: "Dev Users Query", created_by: admin_user,
                                    query: "SELECT id FROM users WHERE username = 'devuser1'")
        post admin_audience_segments_path, params: {
          audience_segment: { name: "Segment from Query" },
          user_query_id: query.id
        }

        created = AudienceSegment.last
        expect(created.users).to contain_exactly(user1)
      end

      it "rejects creation when name is blank" do
        expect do
          post admin_audience_segments_path, params: {
            audience_segment: { name: "" }
          }
        end.not_to change(AudienceSegment, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "GET /admin/audience_segments/:id" do
      let!(:member_user) { create(:user, username: "member1", email: "member1@example.com") }

      before do
        manual_segment.segmented_users.create!(user: member_user)
      end

      it "shows segment details and member table" do
        get admin_audience_segment_path(manual_segment)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Alpha Testers")
        expect(response.body).to include("member1")
      end

      it "searches members by username" do
        other_user = create(:user, username: "other_member")
        manual_segment.segmented_users.create!(user: other_user)

        get admin_audience_segment_path(manual_segment), params: { search: "member1" }
        expect(response.body).to include("member1")
        expect(response.body).not_to include("other_member")
      end
    end

    describe "PATCH /admin/audience_segments/:id" do
      it "updates the segment name" do
        patch admin_audience_segment_path(manual_segment), params: {
          audience_segment: { name: "Updated Alpha" }
        }
        expect(response).to redirect_to(admin_audience_segment_path(manual_segment))
        expect(manual_segment.reload.name).to eq("Updated Alpha")
      end

      it "rejects update when name is blank" do
        patch admin_audience_segment_path(manual_segment), params: {
          audience_segment: { name: "" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(manual_segment.reload.name).to eq("Alpha Testers")
      end

      it "prevents updating automatic system segments" do
        patch admin_audience_segment_path(system_segment), params: {
          audience_segment: { name: "Try to override" }
        }
        expect(response).to redirect_to(admin_audience_segments_path)
        expect(flash[:danger]).to eq(I18n.t("admin.audience_segments_controller.system_segment_protected"))
      end
    end

    describe "POST /admin/audience_segments/:id/add_users" do
      let!(:new_user) { create(:user, username: "new_recruit") }

      it "adds users to an existing segment" do
        expect do
          post add_users_admin_audience_segment_path(manual_segment), params: {
            user_identifiers: "new_recruit"
          }
        end.to change(manual_segment.segmented_users, :count).by(1)

        expect(response).to redirect_to(admin_audience_segment_path(manual_segment))
        expect(flash[:success]).to include("1 user(s) successfully added")
      end

      it "reports already existing users and missing identifiers" do
        manual_segment.segmented_users.create!(user: new_user)

        post add_users_admin_audience_segment_path(manual_segment), params: {
          user_identifiers: "new_recruit, missing_person_404"
        }

        expect(flash[:success]).to include("1 user(s) were already in this segment.")
        expect(flash[:success]).to include("Could not resolve: missing_person_404.")
      end
    end

    describe "DELETE /admin/audience_segments/:id/remove_user" do
      let!(:member) { create(:user) }

      before do
        manual_segment.segmented_users.create!(user: member)
      end

      it "removes an individual user from the segment" do
        expect do
          delete remove_user_admin_audience_segment_path(manual_segment), params: {
            user_id: member.id
          }
        end.to change(manual_segment.segmented_users, :count).by(-1)

        expect(response).to redirect_to(admin_audience_segment_path(manual_segment))
        expect(flash[:success]).to eq(I18n.t("admin.audience_segments_controller.user_removed"))
      end
    end

    describe "POST /admin/audience_segments/:id/remove_users" do
      let!(:member1) { create(:user) }
      let!(:member2) { create(:user) }

      before do
        manual_segment.segmented_users.create!(user: member1)
        manual_segment.segmented_users.create!(user: member2)
      end

      it "removes multiple users in bulk" do
        expect do
          post remove_users_admin_audience_segment_path(manual_segment), params: {
            user_ids: [member1.id, member2.id]
          }
        end.to change(manual_segment.segmented_users, :count).by(-2)

        expect(response).to redirect_to(admin_audience_segment_path(manual_segment))
      end
    end

    describe "DELETE /admin/audience_segments/:id" do
      it "deletes an unlinked manual audience segment" do
        expect do
          delete admin_audience_segment_path(manual_segment)
        end.to change(AudienceSegment, :count).by(-1)

        expect(response).to redirect_to(admin_audience_segments_path)
        expect(flash[:success]).to eq(I18n.t("admin.audience_segments_controller.deleted"))
      end

      it "prevents deleting a segment associated with emails" do
        create(:email, status: "draft", audience_segment: manual_segment)

        expect do
          delete admin_audience_segment_path(manual_segment)
        end.not_to change(AudienceSegment, :count)

        expect(response).to redirect_to(admin_audience_segment_path(manual_segment))
        expect(flash[:danger]).to be_present
      end

      it "prevents deleting a segment associated with billboards" do
        create(:billboard, audience_segment: manual_segment)

        expect do
          delete admin_audience_segment_path(manual_segment)
        end.not_to change(AudienceSegment, :count)

        expect(response).to redirect_to(admin_audience_segment_path(manual_segment))
        expect(flash[:danger]).to be_present
      end

      it "prevents deleting a system automatic segment" do
        expect do
          delete admin_audience_segment_path(system_segment)
        end.not_to change(AudienceSegment, :count)

        expect(response).to redirect_to(admin_audience_segments_path)
        expect(flash[:danger]).to eq(I18n.t("admin.audience_segments_controller.system_segment_protected"))
      end
    end
  end
end
