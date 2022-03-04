require "rails_helper"

RSpec.describe "/admin/organization_memberships", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  before do
    sign_in(admin)
  end

  describe "#create" do
    context "when interacting via a browser" do
      it "errors if a param is missing", :aggregate_failures do
        expect do
          post admin_organization_memberships_path, params: {
            organization_membership: {
              user_id: user.id,
              type_of_user: :a
            }
          }
        end.to not_change(user.organizations, :count)

        expect(response).to redirect_to(admin_user_path(user.id))
        expect(flash[:danger]).to include("does not exist")
      end

      it "errors if a param is invalid", :aggregate_failures do
        expect do
          post admin_organization_memberships_path, params: {
            organization_membership: {
              user_id: user.id,
              type_of_user: :a,
              organization_id: organization.id
            }
          }
        end.to not_change(user.organizations, :count)

        expect(response).to redirect_to(admin_user_path(user.id))
        expect(flash[:danger]).to include("not included in the list")
      end

      it "adds a user to an organization", :aggregate_failures do
        expect do
          post admin_organization_memberships_path, params: {
            organization_membership: {
              user_id: user.id,
              type_of_user: :member,
              organization_id: organization.id
            }
          }
        end.to change(user.organizations, :count).by(1)

        expect(response).to redirect_to(admin_user_path(user.id))
        expect(flash[:success]).to include("successfully added")
      end
    end

    context "when interacting via ajax" do
      it "returns :unprocessable_entity if a param is missing", :aggregate_failures do
        expect do
          post admin_organization_memberships_path, params: {
            organization_membership: {
              user_id: user.id,
              type_of_user: :a
            }
          }, xhr: true
        end.to not_change(user.organizations, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to include("does not exist")
      end

      it "returns :unprocessable_entity if a param is invalid", :aggregate_failures do
        expect do
          post admin_organization_memberships_path, params: {
            organization_membership: {
              user_id: user.id,
              type_of_user: :a,
              organization_id: organization.id
            }
          }, xhr: true
        end.to not_change(user.organizations, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to include("not included in the list")
      end

      it "adds a user to an organization", :aggregate_failures do
        expect do
          post admin_organization_memberships_path, params: {
            organization_membership: {
              user_id: user.id,
              type_of_user: :member,
              organization_id: organization.id
            }
          }, xhr: true
        end.to change(user.organizations, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["result"]).to include("successfully added")
      end
    end
  end

  describe "#update" do
    let(:membership) { create(:organization_membership, user: user, organization: organization, type_of_user: :member) }

    it "returns not found for non existing memberships" do
      expect do
        put admin_organization_membership_path(9999), params: {
          organization_membership: {
            type_of_user: :member
          }
        }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "when interacting via a browser" do
      it "errors if a param is invalid", :aggregate_failures do
        expect do
          put admin_organization_membership_path(membership.id), params: {
            organization_membership: {
              type_of_user: :a
            }
          }
        end.to not_change(membership, :type_of_user)

        expect(response).to redirect_to(admin_user_path(user.id))
        expect(flash[:danger]).to include("not included in the list")
      end

      it "cannot change the user id", :aggregate_failures do
        put admin_organization_membership_path(membership.id), params: {
          organization_membership: {
            type_of_user: :admin,
            user_id: create(:user).id
          }
        }

        expect(membership.reload.user_id).to eq(user.id)
      end

      it "cannot change the organization id", :aggregate_failures do
        put admin_organization_membership_path(membership.id), params: {
          organization_membership: {
            type_of_user: :admin,
            organization_id: create(:organization).id
          }
        }

        expect(membership.reload.organization_id).to eq(organization.id)
      end

      it "changes the membership type of user", :aggregate_failures do
        expect do
          put admin_organization_membership_path(membership.id), params: {
            organization_membership: {
              type_of_user: :admin
            }
          }
        end.to change(user.organizations, :count).by(1)

        expect(membership.reload.organization_id).to eq(organization.id)
        expect(response).to redirect_to(admin_user_path(user.id))
        expect(flash[:success]).to include("successfully updated")
      end
    end

    context "when interacting via ajax" do
      it "errors if a param is invalid", :aggregate_failures do
        expect do
          put admin_organization_membership_path(membership.id), params: {
            organization_membership: {
              type_of_user: :a
            }
          }, xhr: true
        end.to not_change(membership, :type_of_user)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to include("not included in the list")
      end

      it "cannot change the user id", :aggregate_failures do
        put admin_organization_membership_path(membership.id), params: {
          organization_membership: {
            type_of_user: :admin,
            user_id: create(:user).id
          }
        }, xhr: true

        expect(membership.reload.user_id).to eq(user.id)
      end

      it "cannot change the organization id", :aggregate_failures do
        put admin_organization_membership_path(membership.id), params: {
          organization_membership: {
            type_of_user: :admin,
            organization_id: create(:organization).id
          }
        }, xhr: true

        expect(membership.reload.organization_id).to eq(organization.id)
      end

      it "changes the membership type of user", :aggregate_failures do
        expect do
          put admin_organization_membership_path(membership.id), params: {
            organization_membership: {
              type_of_user: :admin
            }
          }, xhr: true
        end.to change(user.organizations, :count).by(1)

        expect(membership.reload.organization_id).to eq(organization.id)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["result"]).to include("successfully updated")
      end
    end
  end

  describe "#destroy" do
    it "returns not found for non existing memberships" do
      expect do
        delete admin_organization_membership_path(9999)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "when interacting via a browser" do
      it "removes the membership of the user from an org", :aggregate_failures do
        membership = create(:organization_membership, user: user, organization: organization)

        expect do
          delete admin_organization_membership_path(membership.id)
        end.to change(user.organizations, :count).by(-1)

        expect(response).to redirect_to(admin_user_path(user.id))
        expect(flash[:success]).to include("successfully removed")
      end
    end

    context "when interacting via ajax" do
      it "removes the membership of the user from an org", :aggregate_failures do
        membership = create(:organization_membership, user: user, organization: organization)

        expect do
          delete admin_organization_membership_path(membership.id), xhr: true
        end.to change(user.organizations, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["result"]).to include("successfully removed")
      end
    end
  end
end
