require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /partnerships" do
    context "when user is logged in" do
      before do
        get "/partnerships"
      end

      it "renders main text" do
        expect(response.body).to include "Partner With"
      end
    end

    context "when user is not logged in" do
      before do
        user = create(:user)
        sign_in user
        get "/partnerships"
      end

      it "renders main text" do
        expect(response.body).to include "Partner With"
      end
    end
  end

  describe "GET /partnerships/:show" do
    let(:user) { create(:user) }

    context "when user is logged in" do
      before do
        sign_in user
      end

      describe "shared basic functionality" do
        it "gets bronze sponsorship page" do
          get "/partnerships/bronze-sponsor"
          expect(response.body).to include("Bronze Sponsorship")
        end
        it "asks user to create org if not created" do
          get "/partnerships/bronze-sponsor"
          expect(response.body).to include("Create an Organization")
        end
        it "asks user to purchase credits if not purchased" do
          organization = create(:organization)
          OrganizationMembership.create(user_id: user.id, organization_id: organization.id, type_of_user: "admin")
          get "/partnerships/bronze-sponsor"
          expect(response.body).to include("Purchase Credits")
        end
        it "includes sponsorship form if organization has credits" do
          organization = create(:organization)
          OrganizationMembership.create(user_id: user.id, organization_id: organization.id, type_of_user: "admin")
          Credit.add_to_org(organization, 100)
          get "/partnerships/bronze-sponsor"
          expect(response.body).to include("This subscription will renew every month")
        end
      end
    end

    context "when user is not logged in" do
      describe "shared basic functionality" do
        it "gets bronze sponsorship page" do
          get "/partnerships/bronze-sponsor"
          expect(response.body).to include("Bronze Sponsorship")
          expect(response.body).to include("Sign in to get started")
        end
      end
    end
  end

  describe "POST /partnerships" do
    let(:user) { create(:user) }
    let(:organization) { create(:organization) }

    context "when user is logged in as an admin and has enough credits" do
      before do
        OrganizationMembership.create(user_id: user.id, organization_id: organization.id, type_of_user: "admin")
        Credit.add_to_org(organization, 2000)
        sign_in user
      end

      it "subscribes to bronze sponsorship" do
        post "/partnerships", params: {
          sponsorship_level: "bronze",
          organization_id: organization.id
        }
        expect(organization.reload.sponsorship_level).to eq("bronze")
      end
      it "subscribes to silver sponsorship" do
        post "/partnerships", params: {
          sponsorship_level: "silver",
          organization_id: organization.id
        }
        expect(organization.reload.sponsorship_level).to eq("silver")
      end
      xit "subscribes to gold sponsorship" do # skipped for now do to high credit need (not sure making this self serve makes sense)
        post "/partnerships", params: {
          sponsorship_level: "gold",
          organization_id: organization.id
        }
        expect(organization.reload.sponsorship_level).to eq("gold")
      end
      it "subscribes to editorial subscription" do
        post "/partnerships", params: {
          sponsorship_level: "devrel",
          organization_id: organization.id
        }
        expect(organization.reload.credits.where(spent: false).size).to eq(1500)
      end
      it "subscribes to media sponsorship" do
        post "/partnerships", params: {
          sponsorship_level: "media",
          organization_id: organization.id,
          sponsorship_amount: 900
        }
        expect(organization.reload.credits.where(spent: false).size).to eq(1100)
      end
      it "subscribes to tag sponsorship" do
        tag = create(:tag)
        post "/partnerships", params: {
          sponsorship_level: "tag",
          organization_id: organization.id,
          sponsorship_amount: 900,
          tag_name: tag.name
        }
        expect(organization.reload.credits.where(spent: false).size).to eq(1700)
        expect(tag.reload.sponsor_organization_id).to eq(organization.id)
      end
      it "updates sponsorship instructions if new instructions" do
        post "/partnerships", params: {
          sponsorship_level: "bronze",
          organization_id: organization.id,
          sponsorship_instructions: "hello there"
        }
        expect(organization.reload.sponsorship_instructions).to include("hello there")
        expect(organization.reload.sponsorship_instructions_updated_at).to be > 30.seconds.ago
      end
    end

    context "when user is logged in as a non-admin" do
      before do
        OrganizationMembership.create(user_id: user.id, organization_id: organization.id, type_of_user: "member")
        Credit.add_to_org(organization, 2000)
        sign_in user
      end

      it "subscribes to bronze sponsorship" do
        expect do
          post "/partnerships", params: {
            sponsorship_level: "bronze",
            organization_id: organization.id
          }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
